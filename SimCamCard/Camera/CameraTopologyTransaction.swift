//
//  CameraTopologyTransaction.swift
//  SimCamCard
//
//  Minimal configuration-transaction seam for CameraSessionController
//  (Week 3 Increment 4 correction — partial-topology rollback).
//
//  Problem solved: configureIfNeeded() adds, inside ONE AVCaptureSession
//  transaction, the video input → photo output → video-data output.
//  If a LATER step is rejected, committing the transaction would leave
//  the earlier objects installed while `isConfigured == false` — a
//  partial topology that a later retry must never face.
//
//  Contract implemented here:
//   - success → exactly one video input, one photo output, one
//     video-data output, one begin/commit pair;
//   - any failure → remove in REVERSE order only the objects added by
//     THIS attempt (pre-existing topology is never touched), commit the
//     clean topology, throw the original CameraSessionError;
//   - a later configure attempt therefore always starts from a clean
//     topology.
//
//  The narrow `CaptureSessionTopology` protocol exists so this ordering
//  contract is unit-testable with a deterministic fake and NO camera
//  hardware. AVCaptureSession satisfies it with its existing methods.
//  The protocol is deliberately NOT Sendable: every call is
//  synchronous on the CameraSessionController actor's serial executor,
//  so no isolation boundary is crossed — no `@unchecked Sendable`,
//  no `nonisolated(unsafe)`.
//

@preconcurrency import AVFoundation

/// Minimal topology-mutation surface used by a single configure
/// attempt. Witnessed directly by AVCaptureSession's existing
/// `beginConfiguration` / `commitConfiguration` / canAdd/add/remove
/// methods (associated types inferred as AVCaptureInput and
/// AVCaptureOutput).
nonisolated protocol CaptureSessionTopology: AnyObject {
    associatedtype VideoInput
    associatedtype CaptureOutput

    func beginConfiguration()
    func commitConfiguration()

    func canAddInput(_ input: VideoInput) -> Bool
    func addInput(_ input: VideoInput)
    func removeInput(_ input: VideoInput)

    func canAddOutput(_ output: CaptureOutput) -> Bool
    func addOutput(_ output: CaptureOutput)
    func removeOutput(_ output: CaptureOutput)
}

extension AVCaptureSession: CaptureSessionTopology {
    // Empty conformance: associated types and witnesses are inferred
    // from AVCaptureSession's existing API (VideoInput ==
    // AVCaptureInput, CaptureOutput == AVCaptureOutput).
}

/// One configure attempt with reverse-order rollback on failure.
nonisolated enum CameraTopologyTransaction {

    /// Adds the video input, then the photo output, then the
    /// video-data output inside a single session configuration
    /// transaction. On any rejection, rolls back exactly the objects
    /// THIS attempt added (reverse order), commits the clean topology,
    /// and rethrows the original CameraSessionError.
    static func apply<Session: CaptureSessionTopology>(
        to session: Session,
        videoInput: Session.VideoInput,
        photoOutput: Session.CaptureOutput,
        videoDataOutput: Session.CaptureOutput
    ) throws {
        session.beginConfiguration()

        var addedVideoInput = false
        var addedPhotoOutput = false
        var addedVideoDataOutput = false

        // Reverse-order removal of only what THIS attempt added, then
        // commit so the session is left in a clean, retryable state.
        // Objects present before beginConfiguration() are never removed.
        func rollback() {
            if addedVideoDataOutput { session.removeOutput(videoDataOutput) }
            if addedPhotoOutput { session.removeOutput(photoOutput) }
            if addedVideoInput { session.removeInput(videoInput) }
            session.commitConfiguration()
        }

        guard session.canAddInput(videoInput) else {
            rollback()
            throw CameraSessionError.cannotAddVideoInput
        }
        session.addInput(videoInput)
        addedVideoInput = true

        guard session.canAddOutput(photoOutput) else {
            rollback()
            throw CameraSessionError.cannotAddPhotoOutput
        }
        session.addOutput(photoOutput)
        addedPhotoOutput = true

        guard session.canAddOutput(videoDataOutput) else {
            rollback()
            throw CameraSessionError.cannotAddVideoDataOutput
        }
        session.addOutput(videoDataOutput)
        addedVideoDataOutput = true

        session.commitConfiguration()
    }
}
