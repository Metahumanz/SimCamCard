//
//  CameraTopologyTransactionTests.swift
//  SimCamCardTests
//
//  Unit tests for the configure-transaction rollback/retry contract
//  (Week 3 Increment 4 correction).
//
//  These test the LOGIC contract only — add ordering, reverse-order
//  rollback, clean topology after failure, and a successful retry —
//  through the minimal CaptureSessionTopology seam with a
//  deterministic fake. No AVCaptureSession, no camera hardware, no
//  simulator dependency.
//

import Testing
@testable import SimCamCard

@MainActor
@Suite("CameraTopologyTransaction")
struct CameraTopologyTransactionTests {

    /// Identity token standing in for AVCaptureInput / AVCaptureOutput.
    /// Only used inside these MainActor-isolated tests; never crosses
    /// an isolation boundary (the seam is not Sendable).
    private final class Token {
        let label: String
        init(_ label: String) { self.label = label }
    }

    /// Deterministic topology fake: records every call in order and
    /// can reject chosen tokens at the `canAdd` gate.
    private final class FakeTopology: CaptureSessionTopology {
        typealias VideoInput = Token
        typealias CaptureOutput = Token

        var beginCount = 0
        var commitCount = 0
        private(set) var inputs: [Token] = []
        private(set) var outputs: [Token] = []
        private(set) var eventLog: [String] = []

        private var rejectedInputs: Set<ObjectIdentifier> = []
        private var rejectedOutputs: Set<ObjectIdentifier> = []

        func reject(input: Token) { rejectedInputs.insert(ObjectIdentifier(input)) }
        func reject(output: Token) { rejectedOutputs.insert(ObjectIdentifier(output)) }
        func allowAll() {
            rejectedInputs.removeAll()
            rejectedOutputs.removeAll()
        }

        func beginConfiguration() {
            beginCount += 1
            eventLog.append("begin")
        }

        func commitConfiguration() {
            commitCount += 1
            eventLog.append("commit")
        }

        func canAddInput(_ input: Token) -> Bool {
            !rejectedInputs.contains(ObjectIdentifier(input))
        }

        func addInput(_ input: Token) {
            inputs.append(input)
            eventLog.append("addInput:\(input.label)")
        }

        func removeInput(_ input: Token) {
            inputs.removeAll { $0 === input }
            eventLog.append("removeInput:\(input.label)")
        }

        func canAddOutput(_ output: Token) -> Bool {
            !rejectedOutputs.contains(ObjectIdentifier(output))
        }

        func addOutput(_ output: Token) {
            outputs.append(output)
            eventLog.append("addOutput:\(output.label)")
        }

        func removeOutput(_ output: Token) {
            outputs.removeAll { $0 === output }
            eventLog.append("removeOutput:\(output.label)")
        }
    }

    // MARK: - Success

    @Test("successful attempt installs exactly one input and two outputs")
    func successfulAttemptInstallsFullTopology() throws {
        let topology = FakeTopology()
        let input = Token("video")
        let photo = Token("photo")
        let videoData = Token("videodata")

        try CameraTopologyTransaction.apply(
            to: topology,
            videoInput: input,
            photoOutput: photo,
            videoDataOutput: videoData
        )

        #expect(topology.beginCount == 1)
        #expect(topology.commitCount == 1)
        #expect(topology.inputs.count == 1)
        #expect(topology.inputs.first === input)
        #expect(topology.outputs.count == 2)
        #expect(topology.outputs[0] === photo)
        #expect(topology.outputs[1] === videoData)
        #expect(topology.eventLog == [
            "begin",
            "addInput:video",
            "addOutput:photo",
            "addOutput:videodata",
            "commit",
        ])
    }

    // MARK: - Failure rollback

    @Test("rejected input leaves an empty, committed topology")
    func rejectedInputRollsBack() {
        let topology = FakeTopology()
        let input = Token("video")
        topology.reject(input: input)

        #expect(throws: CameraSessionError.cannotAddVideoInput) {
            try CameraTopologyTransaction.apply(
                to: topology,
                videoInput: input,
                photoOutput: Token("photo"),
                videoDataOutput: Token("videodata")
            )
        }

        #expect(topology.inputs.isEmpty)
        #expect(topology.outputs.isEmpty)
        #expect(topology.beginCount == 1)
        #expect(topology.commitCount == 1)
    }

    @Test("rejected photo output removes the input, then commits clean")
    func rejectedPhotoOutputRollsBackInput() {
        let topology = FakeTopology()
        let input = Token("video")
        let photo = Token("photo")
        topology.reject(output: photo)

        #expect(throws: CameraSessionError.cannotAddPhotoOutput) {
            try CameraTopologyTransaction.apply(
                to: topology,
                videoInput: input,
                photoOutput: photo,
                videoDataOutput: Token("videodata")
            )
        }

        #expect(topology.inputs.isEmpty)
        #expect(topology.outputs.isEmpty)
        #expect(topology.eventLog == [
            "begin",
            "addInput:video",
            "removeInput:video",
            "commit",
        ])
    }

    @Test("rejected video-data output removes video output, photo output, input in reverse order")
    func rejectedVideoDataOutputRollsBackEverything() {
        let topology = FakeTopology()
        let input = Token("video")
        let photo = Token("photo")
        let videoData = Token("videodata")
        topology.reject(output: videoData)

        #expect(throws: CameraSessionError.cannotAddVideoDataOutput) {
            try CameraTopologyTransaction.apply(
                to: topology,
                videoInput: input,
                photoOutput: photo,
                videoDataOutput: videoData
            )
        }

        #expect(topology.inputs.isEmpty)
        #expect(topology.outputs.isEmpty)
        // The rejected video-data output was never added, so it is not
        // removed; only the two objects actually installed this attempt
        // are removed, in reverse add order.
        #expect(topology.eventLog == [
            "begin",
            "addInput:video",
            "addOutput:photo",
            "removeOutput:photo",
            "removeInput:video",
            "commit",
        ])
    }

    // MARK: - Retry

    @Test("a failed late step followed by an allowed retry yields the full topology")
    func retryAfterLateFailureSucceedsFromCleanTopology() {
        let topology = FakeTopology()
        let input = Token("video")
        let photo = Token("photo")
        let videoData = Token("videodata")

        // Attempt 1: the LATE step (video-data output) is rejected.
        topology.reject(output: videoData)
        #expect(throws: CameraSessionError.cannotAddVideoDataOutput) {
            try CameraTopologyTransaction.apply(
                to: topology,
                videoInput: input,
                photoOutput: photo,
                videoDataOutput: videoData
            )
        }
        #expect(topology.inputs.isEmpty)
        #expect(topology.outputs.isEmpty)
        #expect(topology.beginCount == 1)
        #expect(topology.commitCount == 1)

        // Attempt 2: configuration allowed. Same input/output objects
        // are safe to add again because attempt 1 removed them.
        topology.allowAll()
        do {
            try CameraTopologyTransaction.apply(
                to: topology,
                videoInput: input,
                photoOutput: photo,
                videoDataOutput: videoData
            )
        } catch {
            Issue.record("retry should succeed, got \(error)")
            return
        }

        #expect(topology.beginCount == 2)
        #expect(topology.commitCount == 2)
        #expect(topology.inputs.count == 1)
        #expect(topology.inputs.first === input)
        #expect(topology.outputs.count == 2)
        #expect(topology.outputs[0] === photo)
        #expect(topology.outputs[1] === videoData)
    }
}
