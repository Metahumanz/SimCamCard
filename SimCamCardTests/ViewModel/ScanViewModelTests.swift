//
//  ScanViewModelTests.swift
//  SimCamCardTests
//
//  Unit tests for ScanViewModel — T03 Camera Permission state machine
//  and S02 preview orchestration (Swift Testing).
//
//  Spec sources:
//   - spec/state-inventory.md S02 permissionUnknown / permissionDenied
//     / preview
//   - spec/reference-tests.md T03 Camera Permission:
//     "Allow/deny must produce defined states; denial path must not
//     crash."
//
//  All tests use test-local fakes for authorization and the session
//  controller; no real camera hardware and no native system dialog are
//  involved. These verify STATE/ORCHESTRATION only — native permission
//  UI and real live-frame preview are separate manual verification
//  levels recorded in ai/changes.md.
//
//  Concurrency note (Week 3 Increment 1 correction): the session
//  controller protocol is async and its implementations are actors on
//  dedicated serial executors. Tests await the async orchestration API
//  and assert serialization/idempotency via counters — never via
//  wall-clock timing or thread identity.
//

import Testing
@preconcurrency import AVFoundation
@testable import SimCamCard

@MainActor
@Suite("ScanViewModel")
struct ScanViewModelTests {

    // MARK: - Test fakes

    /// Permission fake: stays MainActor-isolated (no blocking session
    /// work), mirrors the production authorization protocol.
    private final class FakeAuthorization: CameraAuthorizationProviding {
        private var current: CameraAuthorizationStatus
        private let grantsOnRequest: Bool
        private(set) var requestCount = 0

        init(initialStatus: CameraAuthorizationStatus, grantsOnRequest: Bool = false) {
            self.current = initialStatus
            self.grantsOnRequest = grantsOnRequest
        }

        func videoAuthorizationStatus() -> CameraAuthorizationStatus {
            current
        }

        func requestVideoAccess() async -> Bool {
            requestCount += 1
            current = grantsOnRequest ? .authorized : .denied
            return grantsOnRequest
        }
    }

    /// Session fake: an actor, like the production service, so the
    /// configure-once / start-many / stop-many contract is exercised
    /// through the same serialized, await-based API shape.
    private actor FakeSession: CameraSessionControlling {
        nonisolated let session = AVCaptureSession()
        private(set) var configureCount = 0
        private(set) var startCount = 0
        private(set) var stopCount = 0
        private(set) var captureCount = 0
        private let configureError: CameraSessionError?
        private let startError: CameraSessionError?
        private let captureError: CameraSessionError?

        /// Deterministic valid still bytes (content is irrelevant to
        /// state assertions; only presence matters).
        private static let fixtureBytes = Data([0x89, 0x50, 0x4E, 0x47])

        init(
            configureError: CameraSessionError? = nil,
            startError: CameraSessionError? = nil,
            captureError: CameraSessionError? = nil
        ) {
            self.configureError = configureError
            self.startError = startError
            self.captureError = captureError
        }

        func configureIfNeeded() async throws {
            guard configureCount == 0 else { return }
            configureCount += 1
            if let configureError {
                throw configureError
            }
        }

        func start() async throws {
            startCount += 1
            if let startError {
                throw startError
            }
        }

        func stop() async {
            stopCount += 1
        }

        func capturePhoto() async throws -> CapturedPhoto {
            captureCount += 1
            if let captureError {
                throw captureError
            }
            return CapturedPhoto(data: Self.fixtureBytes)
        }
    }

    // MARK: - Fresh state

    @Test("a fresh ViewModel is in permissionUnknown before the scanner appears")
    func freshStateIsPermissionUnknown() {
        let vm = ScanViewModel(
            authorization: FakeAuthorization(initialStatus: .notDetermined),
            sessionController: FakeSession()
        )
        #expect(vm.state == .permissionUnknown)
    }

    // MARK: - notDetermined → granted

    @Test("notDetermined requests access; grant configures/starts session and enters preview")
    func notDeterminedGrantedEntersPreview() async {
        let auth = FakeAuthorization(initialStatus: .notDetermined, grantsOnRequest: true)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()

        #expect(vm.state == .preview)
        #expect(auth.requestCount == 1)
        #expect(await session.configureCount == 1)
        #expect(await session.startCount == 1)
    }

    // MARK: - notDetermined → denied

    @Test("notDetermined denial enters permissionDenied and never starts the session")
    func notDeterminedDeniedEntersDeniedWithoutSession() async {
        let auth = FakeAuthorization(initialStatus: .notDetermined, grantsOnRequest: false)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()

        #expect(vm.state == .permissionDenied)
        #expect(auth.requestCount == 1)
        #expect(await session.configureCount == 0)
        #expect(await session.startCount == 0)
        #expect(await session.stopCount == 0)
    }

    // MARK: - already authorized

    @Test("already authorized starts preview without requesting permission")
    func authorizedSkipsRequestAndStartsPreview() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()

        #expect(vm.state == .preview)
        #expect(auth.requestCount == 0)
        #expect(await session.configureCount == 1)
        #expect(await session.startCount == 1)
    }

    // MARK: - already denied

    @Test("already denied never re-prompts and never starts a session")
    func alreadyDeniedDoesNotRequestOrStart() async {
        let auth = FakeAuthorization(initialStatus: .denied)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()

        #expect(vm.state == .permissionDenied)
        #expect(auth.requestCount == 0)
        #expect(await session.configureCount == 0)
        #expect(await session.startCount == 0)
    }

    // MARK: - restricted

    @Test("restricted is treated as denied: no prompt, no session, permissionDenied state")
    func restrictedMapsToPermissionDenied() async {
        let auth = FakeAuthorization(initialStatus: .restricted)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()

        #expect(vm.state == .permissionDenied)
        #expect(auth.requestCount == 0)
        #expect(await session.configureCount == 0)
        #expect(await session.startCount == 0)
    }

    // MARK: - disappear stops session

    @Test("leaving the scanner stops a running session")
    func disappearStopsSession() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .preview)
        await vm.scannerDidDisappear()

        #expect(await session.stopCount == 1)
    }

    // MARK: - re-entry: configure once, start/stop many

    @Test("re-entering the scanner restarts without duplicate configuration")
    func reentryRestartsWithoutReconfigure() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        // First entry.
        await vm.scannerDidAppear()
        #expect(vm.state == .preview)
        await vm.scannerDidDisappear()

        // Second entry (authorized status persists; configure must be
        // idempotent; start must run again; no duplicate inputs).
        await vm.scannerDidAppear()
        #expect(vm.state == .preview)

        #expect(auth.requestCount == 0)
        #expect(await session.configureCount == 1)
        #expect(await session.startCount == 2)
        #expect(await session.stopCount == 1)
    }

    // MARK: - infrastructure failure ≠ permissionDenied

    @Test("session configuration failure with granted permission enters cameraUnavailable")
    func configureFailureProducesCameraUnavailableNotDenied() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession(configureError: .noVideoDevice)
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()

        #expect(vm.state == .cameraUnavailable(.noVideoDevice))
        #expect(await session.startCount == 0)
    }

    // MARK: - start failure ≠ preview

    @Test("configure succeeds but start fails: cameraUnavailable, never preview")
    func startFailureProducesCameraUnavailableNotPreview() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession(startError: .startFailed)
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()

        // Contract: configure succeeded, start was requested and failed
        // → cameraUnavailable, and critically NOT preview.
        #expect(await session.configureCount == 1)
        #expect(await session.startCount == 1)
        #expect(vm.state == .cameraUnavailable(.startFailed))
        #expect(vm.state != .preview)
    }

    // MARK: - serialization / idempotency contract

    @Test("configureIfNeeded is serialized and idempotent under concurrent orchestration")
    func concurrentConfigureRunsExactlyOnce() async {
        let session = FakeSession()

        // Fire many concurrent configure calls. The actor-serialized
        // fake must run the configuration body exactly once; no data
        // race, no double-configure. Asserted via counters — no
        // wall-clock timing, no thread identity.
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<16 {
                group.addTask {
                    try? await session.configureIfNeeded()
                }
            }
        }

        #expect(await session.configureCount == 1)
    }

    @Test("start/stop remain idempotent across repeated orchestration cycles")
    func startStopAreIdempotentAcrossCycles() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        // Three full appear/disappear cycles.
        for _ in 0..<3 {
            await vm.scannerDidAppear()
            #expect(vm.state == .preview)
            await vm.scannerDidDisappear()
        }

        // Configure ran exactly once for the whole lifetime; start and
        // stop each ran once per cycle. No duplicate configuration.
        #expect(await session.configureCount == 1)
        #expect(await session.startCount == 3)
        #expect(await session.stopCount == 3)
    }

    // MARK: - T04 capture: success

    @Test("preview → capture → session stops → state is captured(photo)")
    func successfulCaptureStopsSessionAndEntersCaptured() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .preview)

        await vm.capture()

        guard case .captured(let photo) = vm.state else {
            Issue.record("expected .captured, got \(vm.state)")
            return
        }
        #expect(!photo.data.isEmpty)
        // Capture success stops the camera session (release hardware).
        #expect(await session.captureCount == 1)
        #expect(await session.stopCount == 1)
        #expect(!vm.isCaptureInFlight)
    }

    // MARK: - T04 capture: failure never produces captured

    @Test("capture failure → session stopped → stable cameraUnavailable, never captured")
    func captureFailureMapsToCameraUnavailableNotCaptured() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession(captureError: .captureFailed)
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .preview)

        await vm.capture()

        // Contract: capture was attempted once, the failure path also
        // STOPS the session (camera released behind the fallback),
        // state is cameraUnavailable and NEVER captured.
        #expect(await session.captureCount == 1)
        #expect(await session.stopCount == 1)
        #expect(vm.state == .cameraUnavailable(.captureFailed))
        #expect(!vm.isCaptureInFlight)
        if case .captured = vm.state {
            Issue.record("capture failure must never enter .captured")
        }
    }

    // MARK: - T04 capture: wrong states ignore capture

    @Test("capture is ignored in permissionDenied")
    func captureIgnoredWhenDenied() async {
        let auth = FakeAuthorization(initialStatus: .denied)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .permissionDenied)

        await vm.capture()

        #expect(vm.state == .permissionDenied)
        #expect(await session.captureCount == 0)
    }

    @Test("capture is ignored before the scanner appears (permissionUnknown)")
    func captureIgnoredWhenPermissionUnknown() async {
        let auth = FakeAuthorization(initialStatus: .notDetermined, grantsOnRequest: true)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)
        #expect(vm.state == .permissionUnknown)

        await vm.capture()

        #expect(vm.state == .permissionUnknown)
        #expect(await session.captureCount == 0)
    }

    @Test("capture is ignored in cameraUnavailable")
    func captureIgnoredWhenCameraUnavailable() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession(configureError: .noVideoDevice)
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .cameraUnavailable(.noVideoDevice))

        await vm.capture()

        #expect(vm.state == .cameraUnavailable(.noVideoDevice))
        #expect(await session.captureCount == 0)
    }

    // MARK: - T04 capture: single in-flight contract

    @Test("a second capture while one is in flight is ignored (single-card contract)")
    func doubleTapStartsOnlyOneCapture() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .preview)

        // Simulate a fast double tap: two capture() calls racing. The
        // ViewModel's isCaptureInFlight guard (MainActor-serialized)
        // plus the service's in-flight guard ensure only one reaches
        // the camera service. No wall-clock timing involved.
        async let first: Void = vm.capture()
        async let second: Void = vm.capture()
        _ = await (first, second)

        #expect(await session.captureCount == 1)
        guard case .captured = vm.state else {
            Issue.record("expected .captured, got \(vm.state)")
            return
        }
        #expect(!vm.isCaptureInFlight)
    }

    // MARK: - T04: re-entry after capture restarts cleanly

    @Test("leaving the captured state and re-entering restarts preview without reconfigure")
    func reentryAfterCaptureRestartsPreview() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        // First visit: preview → capture → captured.
        await vm.scannerDidAppear()
        await vm.capture()
        guard case .captured = vm.state else {
            Issue.record("expected .captured, got \(vm.state)")
            return
        }
        await vm.scannerDidDisappear()

        // Re-enter: configure stays at 1, start runs again, preview.
        await vm.scannerDidAppear()
        #expect(vm.state == .preview)
        #expect(await session.configureCount == 1)
        #expect(await session.startCount == 2)
        #expect(await session.stopCount == 2) // capture-stop + disappear-stop
    }
}
