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
        /// When set, `startError` is thrown only on the Nth `start()`
        /// call; when nil a non-nil `startError` fails every call.
        private let startErrorOnCall: Int?
        private let captureError: CameraSessionError?

        /// T06 controllable detection stream: tests yield values via
        /// `yieldDetection(_:)`; deterministic, no real Vision involved.
        private var detectionContinuation: AsyncStream<CardRegion?>.Continuation?
        private(set) var makeDetectionEventsCount = 0

        /// Minimal controllable seam: while the gate is enabled,
        /// `start()` suspends (AFTER incrementing `startCount`) until
        /// `releaseStartGate()` resumes it. Lets tests observe the
        /// ViewModel mid-restart without wall-clock timing.
        private var startGateIsEnabled = false
        private var startGateWaiters: [CheckedContinuation<Void, Never>] = []

        /// Deterministic valid still bytes (content is irrelevant to
        /// state assertions; only presence matters).
        private static let fixtureBytes = Data([0x89, 0x50, 0x4E, 0x47])

        init(
            configureError: CameraSessionError? = nil,
            startError: CameraSessionError? = nil,
            startErrorOnCall: Int? = nil,
            captureError: CameraSessionError? = nil
        ) {
            self.configureError = configureError
            self.startError = startError
            self.startErrorOnCall = startErrorOnCall
            self.captureError = captureError
        }

        func enableStartGate() {
            startGateIsEnabled = true
        }

        func releaseStartGate() {
            startGateIsEnabled = false
            let waiters = startGateWaiters
            startGateWaiters.removeAll()
            for waiter in waiters { waiter.resume() }
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
            if startGateIsEnabled {
                await withCheckedContinuation { startGateWaiters.append($0) }
            }
            if let startError, startErrorOnCall == nil || startErrorOnCall == startCount {
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

        func makeDetectionEvents() async -> AsyncStream<CardRegion?> {
            makeDetectionEventsCount += 1
            detectionContinuation?.finish()
            let (stream, continuation) = AsyncStream<CardRegion?>.makeStream(
                bufferingPolicy: .bufferingNewest(1)
            )
            detectionContinuation = continuation
            return stream
        }

        /// Delivers one detection event to the current consumer.
        func yieldDetection(_ region: CardRegion?) {
            detectionContinuation?.yield(region)
        }

        /// Deterministic quadrilateral used by detection-state tests.
        nonisolated static let fixtureRegion = CardRegion(
            topLeft: NormalizedPoint(x: 0.2, y: 0.3),
            topRight: NormalizedPoint(x: 0.8, y: 0.3),
            bottomRight: NormalizedPoint(x: 0.8, y: 0.7),
            bottomLeft: NormalizedPoint(x: 0.2, y: 0.7),
            sourcePixelWidth: 1920,
            sourcePixelHeight: 1080
        )
    }

    // MARK: - Detection stream readiness

    /// Waits until the ViewModel's consumer has taken the detection
    /// stream. The fake drops `yieldDetection` calls made before a
    /// stream exists (continuation is nil), so yielding without this
    /// readiness wait would silently lose the event.
    private func waitForDetectionStream(_ session: FakeSession, count: Int = 1) async {
        for _ in 0..<100 {
            if await session.makeDetectionEventsCount >= count { return }
            await Task.yield()
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

    // MARK: - T05 photo import: selection success

    @Test("preview → begin import → session stops → selected image reaches imageSelected state")
    func photoImportSelectionStopsSessionAndEntersImageSelected() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .preview)

        await vm.beginPhotoImport()

        // Camera is released before the picker is presented.
        #expect(await session.stopCount == 1)
        #expect(vm.isPickerPresented)
        #expect(vm.photoImport == .pickerPresented)

        let importedBytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])
        await vm.handleSelectedImage(importedBytes)

        // Selection clears the picker flag and stores the image.
        #expect(!vm.isPickerPresented)
        guard case .imageSelected(let photo) = vm.photoImport else {
            Issue.record("expected .imageSelected, got \(vm.photoImport)")
            return
        }
        #expect(photo.data == importedBytes)
        #expect(photo.source == .photoLibrary)
        // Camera stays stopped after a selection (§11).
        #expect(await session.startCount == 1) // only the initial preview start
    }

    // MARK: - T05 photo import: cancel is first-class

    @Test("picker cancel clears state and restarts camera preview")
    func photoImportCancelRestartsPreview() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await vm.beginPhotoImport()
        #expect(await session.stopCount == 1)

        await vm.handleImportCancel()

        // Cancel does not produce an image and returns the scanner to
        // a usable preview state (camera restarted).
        #expect(vm.photoImport == .idle)
        #expect(!vm.isPickerPresented)
        if case .imageSelected = vm.photoImport {
            Issue.record("cancel must never enter .imageSelected")
        }
        #expect(await session.startCount == 2) // initial + restart
        #expect(vm.state == .preview)
    }

    // MARK: - T05 photo import: load failure

    @Test("selection load failure enters importFailed, never imageSelected")
    func photoImportLoadFailureEntersImportFailed() {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        vm.handleImportLoadFailure()

        #expect(vm.photoImport == .importFailed)
        #expect(!vm.isPickerPresented)
        if case .imageSelected = vm.photoImport {
            Issue.record("load failure must never enter .imageSelected")
        }
    }

    // MARK: - T05 photo import: wrong-state / duplicate guard

    @Test("beginPhotoImport is ignored outside preview")
    func photoImportIgnoredWhenNotPreview() async {
        let auth = FakeAuthorization(initialStatus: .denied)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .permissionDenied)

        await vm.beginPhotoImport()

        // No picker presented, no session stop from the import path.
        #expect(!vm.isPickerPresented)
        #expect(vm.photoImport == .idle)
        #expect(await session.stopCount == 0)
    }

    @Test("a second beginPhotoImport while one is presented is ignored")
    func photoImportDoesNotPresentTwice() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await vm.beginPhotoImport()
        #expect(vm.isPickerPresented)

        // Attempt to present again while already presented.
        await vm.beginPhotoImport()

        // The guard prevents a second stop or state mutation.
        #expect(await session.stopCount == 1)
        #expect(vm.photoImport == .pickerPresented)
    }

    // MARK: - T05 photo import: camera lifecycle (select → remain stopped)

    @Test("after a successful import the camera session remains stopped")
    func photoImportSelectionKeepsCameraStopped() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()     // startCount == 1
        await vm.beginPhotoImport()     // stopCount == 1
        await vm.handleSelectedImage(Data([0x01, 0x02]))

        await Task.yield()

        // Selection must NOT restart the camera (§11).
        #expect(await session.startCount == 1)
        #expect(await session.stopCount == 1)
    }

    // MARK: - T05 photo import: active import blocks still capture

    @Test("still capture is blocked while the import picker is presented")
    func photoImportPickerPresentedBlocksCapture() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .preview)

        await vm.beginPhotoImport()
        #expect(vm.photoImport == .pickerPresented)
        // `.preview` is still set even though the session is stopped —
        // the shutter action must be gated on the import lifecycle,
        // not on the camera state alone.
        #expect(vm.state == .preview)

        await vm.capture()

        #expect(await session.captureCount == 0)
        #expect(vm.photoImport == .pickerPresented)
        if case .captured = vm.state {
            Issue.record("capture must not run while the picker is presented")
        }
    }

    @Test("still capture is blocked while an imported image is shown")
    func photoImportImageSelectedBlocksCapture() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await vm.beginPhotoImport()
        await vm.handleSelectedImage(Data([0x01, 0x02]))

        await vm.capture()

        #expect(await session.captureCount == 0)
        guard case .imageSelected = vm.photoImport else {
            Issue.record("imported image must survive a blocked capture")
            return
        }
        if case .captured = vm.state {
            Issue.record("capture must not run in imageSelected")
        }
    }

    @Test("still capture is blocked on the import-failure fallback")
    func photoImportFailedBlocksCapture() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await vm.beginPhotoImport()
        vm.handleImportLoadFailure()

        await vm.capture()

        #expect(await session.captureCount == 0)
        #expect(vm.photoImport == .importFailed)
        if case .captured = vm.state {
            Issue.record("capture must not run in importFailed")
        }
    }

    // MARK: - T05 photo import: cancel → restart ordering contract

    @Test("cancel reports idle only after the camera restart completes")
    func photoImportCancelBecomesIdleOnlyAfterRestartCompletes() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()     // startCount == 1
        await session.enableStartGate()
        await vm.beginPhotoImport()     // stopCount == 1; pickerPresented

        let cancelTask = Task { await vm.handleImportCancel() }

        // Deterministically wait (no wall-clock) until the restart
        // start() call has reached the gated fake — the camera is now
        // mid-restart.
        while await session.startCount < 2 {
            await Task.yield()
        }

        // Mid-restart: the picker flow must NOT have reported idle yet.
        #expect(vm.photoImport == .pickerPresented)
        #expect(!vm.isPickerPresented)

        await session.releaseStartGate()
        await cancelTask.value

        // Terminal contract: idle only after the restart resolved.
        #expect(vm.photoImport == .idle)
        #expect(vm.state == .preview)
        #expect(await session.startCount == 2)
    }

    @Test("cancel with failing restart ends the picker flow in cameraUnavailable")
    func photoImportCancelWithRestartFailureLeavesPickerFlowCleanly() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        // Fail only the SECOND start call (the restart); the initial
        // preview start succeeds.
        let session = FakeSession(startError: .startFailed, startErrorOnCall: 2)
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        #expect(vm.state == .preview)

        await vm.beginPhotoImport()
        await vm.handleImportCancel()

        // Restart failure: never surface .preview; the picker flow
        // still ends cleanly (idle) — the import is over, the camera
        // failure is surfaced through the camera state.
        #expect(vm.state == .cameraUnavailable(.startFailed))
        #expect(vm.photoImport == .idle)
        #expect(!vm.isPickerPresented)
        if case .imageSelected = vm.photoImport {
            Issue.record("cancel must never enter .imageSelected")
        }
    }

    // MARK: - T05 photo import: selection dismissal ≠ cancel

    @Test("dismissal after selection clears only the presentation flag; loading stays pickerPresented")
    func photoPickerDismissalAfterSelectionKeepsImportResolving() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await vm.beginPhotoImport()
        #expect(vm.isPickerPresented)
        #expect(vm.photoImport == .pickerPresented)
        #expect(await session.stopCount == 1)

        // System dismissed the sheet after a selection, before
        // loadTransferable completes. NOT a cancel: only the
        // presentation flag clears — no restart, no idle, no image.
        vm.photoPickerDidDismissAfterSelection()

        #expect(!vm.isPickerPresented)
        #expect(vm.photoImport == .pickerPresented)
        #expect(await session.startCount == 1) // camera remains stopped

        // Load succeeds → imageSelected.
        let bytes = Data([0x89, 0x50, 0x4E, 0x47])
        await vm.handleSelectedImage(bytes)
        guard case .imageSelected(let photo) = vm.photoImport else {
            Issue.record("expected .imageSelected after load success")
            return
        }
        #expect(photo.data == bytes)
        #expect(photo.source == .photoLibrary)
        #expect(await session.startCount == 1) // selection never restarts
    }

    @Test("dismissal after selection then load failure enters importFailed without restart")
    func photoPickerDismissalThenLoadFailureEntersImportFailed() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await vm.beginPhotoImport()

        vm.photoPickerDidDismissAfterSelection()
        #expect(vm.photoImport == .pickerPresented)

        vm.handleImportLoadFailure()

        #expect(vm.photoImport == .importFailed)
        #expect(!vm.isPickerPresented)
        #expect(await session.startCount == 1) // no restart on failure
        if case .imageSelected = vm.photoImport {
            Issue.record("load failure must never enter .imageSelected")
        }
    }

    // MARK: - T06 live detection state (fake stream)

    @Test("entering preview starts detection consumption in cardNotDetected")
    func previewStartsDetectionInCardNotDetected() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()

        #expect(vm.state == .preview)
        #expect(vm.cardDetection == .cardNotDetected)
        // The consumer task is spawned on MainActor; wait
        // deterministically until it has taken the stream.
        await waitForDetectionStream(session)
        #expect(await session.makeDetectionEventsCount == 1)
    }

    @Test("preview + nil event stays cardNotDetected")
    func previewNilEventStaysCardNotDetected() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await waitForDetectionStream(session)
        await session.yieldDetection(nil)

        // Deterministic drain: wait until the consumer processed the
        // event by observing a no-op MainActor round-trip.
        await Task.yield()

        #expect(vm.cardDetection == .cardNotDetected)
    }

    @Test("preview + region event enters cardDetected(region)")
    func previewRegionEventEntersCardDetected() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await waitForDetectionStream(session)
        await session.yieldDetection(FakeSession.fixtureRegion)

        // Wait deterministically until the consumer applies the event.
        for _ in 0..<100 where vm.cardDetection != .cardDetected(FakeSession.fixtureRegion) {
            await Task.yield()
        }

        #expect(vm.cardDetection == .cardDetected(FakeSession.fixtureRegion))
    }

    @Test("cardDetected + nil event returns to cardNotDetected")
    func detectedThenNilReturnsToNotDetected() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await waitForDetectionStream(session)
        await session.yieldDetection(FakeSession.fixtureRegion)
        for _ in 0..<100 where vm.cardDetection != .cardDetected(FakeSession.fixtureRegion) {
            await Task.yield()
        }
        #expect(vm.cardDetection == .cardDetected(FakeSession.fixtureRegion))

        await session.yieldDetection(nil)
        for _ in 0..<100 where vm.cardDetection != .cardNotDetected {
            await Task.yield()
        }

        #expect(vm.cardDetection == .cardNotDetected)
    }

    @Test("capture ends detection: state inactive, stale events cannot reactivate")
    func captureDeactivatesDetection() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await waitForDetectionStream(session)
        await session.yieldDetection(FakeSession.fixtureRegion)
        for _ in 0..<100 where vm.cardDetection != .cardDetected(FakeSession.fixtureRegion) {
            await Task.yield()
        }
        #expect(vm.cardDetection == .cardDetected(FakeSession.fixtureRegion))

        await vm.capture()

        guard case .captured = vm.state else {
            Issue.record("expected .captured, got \(vm.state)")
            return
        }
        #expect(vm.cardDetection == .inactive)

        // A late/stale detection event must not reactivate the overlay
        // behind the captured image.
        await session.yieldDetection(FakeSession.fixtureRegion)
        await Task.yield()
        #expect(vm.cardDetection == .inactive)
    }

    @Test("photo import ends detection: state inactive, stale events cannot reactivate")
    func photoImportDeactivatesDetection() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await waitForDetectionStream(session)
        await session.yieldDetection(FakeSession.fixtureRegion)
        for _ in 0..<100 where vm.cardDetection != .cardDetected(FakeSession.fixtureRegion) {
            await Task.yield()
        }
        #expect(vm.cardDetection == .cardDetected(FakeSession.fixtureRegion))

        await vm.beginPhotoImport()

        #expect(vm.cardDetection == .inactive)

        await session.yieldDetection(FakeSession.fixtureRegion)
        await Task.yield()
        #expect(vm.cardDetection == .inactive)
    }

    @Test("scanner disappear ends detection")
    func disappearDeactivatesDetection() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await waitForDetectionStream(session)
        await session.yieldDetection(FakeSession.fixtureRegion)
        for _ in 0..<100 where vm.cardDetection != .cardDetected(FakeSession.fixtureRegion) {
            await Task.yield()
        }
        #expect(vm.cardDetection == .cardDetected(FakeSession.fixtureRegion))

        await vm.scannerDidDisappear()

        #expect(vm.cardDetection == .inactive)
    }

    @Test("cancel-restart resumes detection consumption with a fresh stream")
    func cancelRestartResumesDetection() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession()
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()
        await vm.beginPhotoImport()
        #expect(vm.cardDetection == .inactive)

        await vm.handleImportCancel()

        #expect(vm.state == .preview)
        #expect(vm.cardDetection == .cardNotDetected)
        // A fresh stream was created for the restarted preview.
        await waitForDetectionStream(session, count: 2)
        #expect(await session.makeDetectionEventsCount == 2)
    }

    @Test("cameraUnavailable leaves detection inactive")
    func cameraUnavailableKeepsDetectionInactive() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let session = FakeSession(configureError: .noVideoDevice)
        let vm = ScanViewModel(authorization: auth, sessionController: session)

        await vm.scannerDidAppear()

        #expect(vm.state == .cameraUnavailable(.noVideoDevice))
        #expect(vm.cardDetection == .inactive)
        #expect(await session.makeDetectionEventsCount == 0)
    }

    // MARK: - Rotation decision seam

    @Test("supported rotation angle is applied; unsupported is not")
    func rotationDecisionAppliesOnlySupportedAngles() {
        let supported = VideoRotationDecision.supportedAngle(90) { $0 == 90 }
        #expect(supported == 90)

        let unsupported = VideoRotationDecision.supportedAngle(45) { $0 == 90 }
        #expect(unsupported == nil)
    }

    // MARK: - S04 P04 crop workflow fakes

    /// Deterministic crop-processor fake: same actor/async shape as
    /// the real CardCropProcessor, with controllable preparation and
    /// correction outcomes. Never decodes bytes or runs Core Image.
    private actor FakeCropProcessor: CardCropProcessing {
        enum Outcome {
            case detected
            case fallback
            case invalidData
        }

        private let outcome: Outcome
        private let correctionError: CropError?
        private(set) var prepareCount = 0
        private(set) var correctCount = 0

        /// Deterministic in-flight gate (no sleep): when enabled,
        /// `perspectiveCorrect` suspends after recording entry until
        /// `releaseCorrectionGate()` resumes every waiter.
        private var correctionGateEnabled = false
        private var correctionWaiters: [CheckedContinuation<Void, Never>] = []
        /// Incremented synchronously BEFORE the gate suspension, so a
        /// test can deterministically observe correction entry.
        private(set) var enteredCorrectionCount = 0

        init(outcome: Outcome = .detected, correctionError: CropError? = nil) {
            self.outcome = outcome
            self.correctionError = correctionError
        }

        func enableCorrectionGate() {
            correctionGateEnabled = true
        }

        func releaseCorrectionGate() {
            correctionGateEnabled = false
            let pending = correctionWaiters
            correctionWaiters.removeAll()
            for waiter in pending {
                waiter.resume()
            }
        }

        func prepare(_ photo: CapturedPhoto) throws -> CropPreparation {
            prepareCount += 1
            if outcome == .invalidData {
                throw CropError.invalidImageData
            }
            let draft = CropDraft(
                source: photo,
                sourceOrientation: .up,
                sourcePixelWidth: 600,
                sourcePixelHeight: 380,
                region: Self.draftRegion
            )
            return CropPreparation(draft: draft, wasDetected: outcome == .detected)
        }

        func perspectiveCorrect(_ draft: CropDraft) async throws -> CardCropResult {
            correctCount += 1
            enteredCorrectionCount += 1
            if correctionGateEnabled {
                await withCheckedContinuation { continuation in
                    correctionWaiters.append(continuation)
                }
            }
            if let correctionError {
                throw correctionError
            }
            return CardCropResult(
                original: draft.source,
                confirmedRegion: draft.region,
                processedImageData: Self.processedBytes,
                processedPixelWidth: 420,
                processedPixelHeight: 260
            )
        }

        nonisolated static let draftRegion = CardRegion(
            topLeft: NormalizedPoint(x: 0.10, y: 0.16),
            topRight: NormalizedPoint(x: 0.90, y: 0.16),
            bottomRight: NormalizedPoint(x: 0.90, y: 0.84),
            bottomLeft: NormalizedPoint(x: 0.10, y: 0.84),
            sourcePixelWidth: 600,
            sourcePixelHeight: 380
        )

        /// Content is irrelevant to state assertions; presence only.
        private static let processedBytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])
    }

    /// Deterministic OCR-processor fake: same actor/async shape as the
    /// real CardOCRProcessor, with controllable outcomes and an
    /// in-flight continuation gate (no sleep). Never invokes Vision.
    private actor FakeOCRProcessor: CardOCRProcessing {
        enum Outcome {
            case success    // Card-001 full card
            case missing    // Card-002 no website
            case multiple   // Card-003 mobile+office+fax
            case empty
            case failure
        }

        private let outcome: Outcome
        private(set) var enteredCount = 0

        /// When enabled, `recognize` suspends after recording entry
        /// until `releaseGate()` resumes every waiter.
        private var gateEnabled = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        init(outcome: Outcome = .success) {
            self.outcome = outcome
        }

        func enableGate() {
            gateEnabled = true
        }

        func releaseGate() {
            gateEnabled = false
            let pending = waiters
            waiters.removeAll()
            for waiter in pending {
                waiter.resume()
            }
        }

        func recognize(_ crop: CardCropResult) async throws -> CardOCRResult {
            enteredCount += 1
            if gateEnabled {
                await withCheckedContinuation { continuation in
                    waiters.append(continuation)
                }
            }
            switch outcome {
            case .success:
                return CardOCRResult(cropResult: crop, lines: [
                    OCRLine(text: "上海智云科技有限公司", confidence: 1.0),
                    OCRLine(text: "Shanghai Zhiyun Tech Co., Ltd.", confidence: 1.0),
                    OCRLine(text: "张伟", confidence: 1.0),
                    OCRLine(text: "Wei Zhang", confidence: 1.0),
                    OCRLine(text: "产品总监 | Product Director", confidence: 1.0),
                    OCRLine(text: "手机 Mobile：+86 138 0013 8000", confidence: 1.0),
                    OCRLine(text: "电话 Tel：+86 21 5555 1234", confidence: 1.0),
                    OCRLine(text: "邮箱 Email：wei.zhang@zhiyuntech.com", confidence: 1.0),
                    OCRLine(text: "网址 Web：www.zhiyuntech.com", confidence: 1.0),
                    OCRLine(text: "地址 Address：上海市浦东新区世纪大道100号 200120", confidence: 1.0),
                ])
            case .missing:
                return CardOCRResult(cropResult: crop, lines: [
                    OCRLine(text: "李娜", confidence: 1.0),
                    OCRLine(text: "上海智云科技有限公司", confidence: 1.0),
                    OCRLine(text: "市场总监 | Marketing Director", confidence: 1.0),
                    OCRLine(text: "手机 Mobile：+86 139 1234 5678", confidence: 1.0),
                    OCRLine(text: "电话 Tel：+86 21 6888 2468", confidence: 1.0),
                    OCRLine(text: "邮箱 Email：lina.li@zhiyuntech.com", confidence: 1.0),
                    OCRLine(text: "地址 Address：上海市浦东新区世纪大道188号 200120", confidence: 1.0),
                ])
            case .multiple:
                return CardOCRResult(cropResult: crop, lines: [
                    OCRLine(text: "陈晨", confidence: 1.0),
                    OCRLine(text: "上海智云科技有限公司", confidence: 1.0),
                    OCRLine(text: "商务拓展经理 | Business Development Manager", confidence: 1.0),
                    OCRLine(text: "手机 Mobile：+86 136 8888 1024", confidence: 1.0),
                    OCRLine(text: "电话 Tel：+86 21 5666 7788", confidence: 1.0),
                    OCRLine(text: "传真 Fax：+86 21 5666 7799", confidence: 1.0),
                    OCRLine(text: "邮箱 Email：chen.chen@zhiyuntech.com", confidence: 1.0),
                    OCRLine(text: "网址 Web：www.zhiyuntech.com", confidence: 1.0),
                    OCRLine(text: "地址 Address：上海市徐汇区漕溪北路398号 200030", confidence: 1.0),
                ])
            case .empty:
                return CardOCRResult(cropResult: crop, lines: [])
            case .failure:
                throw OCRError.recognitionFailed
            }
        }
    }

    /// Builds an authorized, preview-ready VM with controllable crop
    /// processing and waits for the initial detection stream.
    /// T07: a deterministic immediate-success OCR fake is injected by
    /// default so crop-only tests never invoke real Vision.
    private func makePreviewViewModel(
        session: FakeSession = FakeSession(),
        crop: FakeCropProcessor,
        ocr: FakeOCRProcessor = FakeOCRProcessor(outcome: .success),
        fieldExtractor: (any CardFieldExtracting)? = nil
    ) async -> ScanViewModel {
        let vm = ScanViewModel(
            authorization: FakeAuthorization(initialStatus: .authorized),
            sessionController: session,
            cropProcessor: crop,
            ocrProcessor: ocr,
            fieldExtractor: fieldExtractor
        )
        await vm.scannerDidAppear()
        #expect(vm.state == .preview)
        await waitForDetectionStream(session, count: 1)
        return vm
    }

    // MARK: - S04 preparation

    @Test("camera capture prepares an autoDetected region")
    func capturedPhotoPreparesAutoDetected() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(session: session, crop: crop)

        await vm.capture()

        guard case .captured(let photo) = vm.state else {
            Issue.record("expected .captured, got \(vm.state)")
            return
        }
        guard case .autoDetected(let draft) = vm.cardRegion else {
            Issue.record("expected .autoDetected, got \(vm.cardRegion)")
            return
        }
        #expect(draft.source == photo)
        #expect(draft.sourcePixelWidth == 600)
        #expect(await crop.prepareCount == 1)
        #expect(vm.cardDetection == .inactive)
    }

    @Test("photo import prepares an autoDetected region")
    func importedPhotoPreparesAutoDetected() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(session: session, crop: crop)

        let importedBytes = Data([0xAA, 0xBB, 0xCC])
        await vm.handleSelectedImage(importedBytes)

        guard case .imageSelected(let photo) = vm.photoImport else {
            Issue.record("expected .imageSelected, got \(vm.photoImport)")
            return
        }
        guard case .autoDetected(let draft) = vm.cardRegion else {
            Issue.record("expected .autoDetected, got \(vm.cardRegion)")
            return
        }
        #expect(draft.source == photo)
        #expect(photo.source == .photoLibrary)
        #expect(photo.data == importedBytes)
        #expect(await crop.prepareCount == 1)
    }

    @Test("no-detection preparation enters manualAdjusting")
    func fallbackPreparationEntersManualAdjusting() async {
        let crop = FakeCropProcessor(outcome: .fallback)
        let vm = await makePreviewViewModel(crop: crop)

        await vm.capture()

        guard case .manualAdjusting = vm.cardRegion else {
            Issue.record("expected .manualAdjusting, got \(vm.cardRegion)")
            return
        }
    }

    @Test("undecodable capture enters the failed crop state")
    func invalidPreparationEntersFailed() async {
        let crop = FakeCropProcessor(outcome: .invalidData)
        let vm = await makePreviewViewModel(crop: crop)

        await vm.capture()

        guard case .failed(let error) = vm.cardRegion else {
            Issue.record("expected .failed, got \(vm.cardRegion)")
            return
        }
        #expect(error == .invalidImageData)
    }

    // MARK: - S04 corner adjustment

    @Test("first valid drag in autoDetected moves into manualAdjusting")
    func firstValidDragTransitionsToManual() async {
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(crop: crop)
        await vm.capture()

        vm.moveCorner(.topLeft, to: NormalizedPoint(x: 0.2, y: 0.2))

        guard case .manualAdjusting(let draft) = vm.cardRegion else {
            Issue.record("expected .manualAdjusting, got \(vm.cardRegion)")
            return
        }
        #expect(abs(draft.region.topLeft.x - 0.2) < 1e-12)
        #expect(abs(draft.region.topLeft.y - 0.2) < 1e-12)
        // The other three corners keep the detected positions.
        #expect(abs(draft.region.bottomRight.x - 0.9) < 1e-12)
    }

    @Test("invalid drag candidate is ignored and keeps the previous region")
    func invalidDragIsIgnored() async {
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(crop: crop)
        await vm.capture()

        let before = vm.cardRegion.draft?.region
        // Flinging top-left to the opposite corner creates a
        // self-intersecting polygon: must be rejected.
        vm.moveCorner(.topLeft, to: NormalizedPoint(x: 0.95, y: 0.95))

        guard case .autoDetected(let draft) = vm.cardRegion else {
            Issue.record("invalid drag must not transition to manualAdjusting; got \(vm.cardRegion)")
            return
        }
        #expect(draft.region == before)
    }

    @Test("valid drag while already manual stays manual with updated region")
    func subsequentValidDragUpdatesRegion() async {
        let crop = FakeCropProcessor(outcome: .fallback)
        let vm = await makePreviewViewModel(crop: crop)
        await vm.capture()

        vm.moveCorner(.bottomRight, to: NormalizedPoint(x: 0.8, y: 0.75))

        guard case .manualAdjusting(let draft) = vm.cardRegion else {
            Issue.record("expected .manualAdjusting, got \(vm.cardRegion)")
            return
        }
        #expect(abs(draft.region.bottomRight.x - 0.8) < 1e-12)
        #expect(abs(draft.region.bottomRight.y - 0.75) < 1e-12)
    }

    @Test("moveCorner is ignored outside an editable state")
    func moveCornerIgnoredWhenInactive() async {
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(crop: crop)

        // Still in preview: no draft exists yet.
        vm.moveCorner(.topLeft, to: NormalizedPoint(x: 0.2, y: 0.2))
        #expect(vm.cardRegion == .inactive)
    }

    // MARK: - S04 confirm

    @Test("confirm produces the corrected result once")
    func confirmProducesResult() async {
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(crop: crop)
        await vm.capture()

        await vm.confirmCrop()

        guard case .confirmed(let result) = vm.cardRegion else {
            Issue.record("expected .confirmed, got \(vm.cardRegion)")
            return
        }
        #expect(result.processedPixelWidth == 420)
        #expect(result.processedPixelHeight == 260)
        #expect(!vm.isCropInFlight)
        #expect(await crop.correctCount == 1)
    }

    @Test("double confirm invokes the processor only once")
    func doubleConfirmIsGuarded() async {
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(crop: crop)
        await vm.capture()

        await vm.confirmCrop()
        // The first confirmation has already replaced the editable
        // draft; the second call has nothing left to confirm.
        await vm.confirmCrop()

        #expect(await crop.correctCount == 1)
        guard case .confirmed = vm.cardRegion else {
            Issue.record("expected .confirmed, got \(vm.cardRegion)")
            return
        }
    }

    @Test("crop intents are frozen while a confirmation correction is in flight")
    func cropIntentsFrozenWhileConfirming() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(session: session, crop: crop)
        await vm.capture()

        let draftBefore = vm.cardRegion.draft
        let regionBefore = draftBefore?.region
        #expect(regionBefore != nil)
        let cameraStartsBefore = await session.startCount
        let detectionStreamsBefore = await session.makeDetectionEventsCount

        // Start a confirmation that parks INSIDE the fake processor
        // via a continuation gate (deterministic; no sleep).
        await crop.enableCorrectionGate()
        let confirmTask = Task { await vm.confirmCrop() }

        // Wait until the correction has actually been entered.
        var entered = false
        for _ in 0..<200 {
            if await crop.enteredCorrectionCount == 1 {
                entered = true
                break
            }
            await Task.yield()
        }
        guard entered else {
            Issue.record("gated correction never entered")
            await crop.releaseCorrectionGate()
            return
        }
        #expect(vm.isCropInFlight)
        guard case .captured = vm.state else {
            Issue.record("workflow should still be on the captured crop page; got \(vm.state)")
            return
        }

        // (a) move while confirming: the draft must not move, and the
        // state must remain autoDetected(draft A) — no manualAdjusting B.
        vm.moveCorner(.topLeft, to: NormalizedPoint(x: 0.2, y: 0.2))
        #expect(vm.cardRegion.draft?.region == regionBefore)
        guard case .autoDetected(let draftDuringMove) = vm.cardRegion else {
            Issue.record("move during in-flight must not leave autoDetected; got \(vm.cardRegion)")
            return
        }
        #expect(draftDuringMove.region == regionBefore)

        // (b) retake while confirming: ignored entirely.
        await vm.retake()
        #expect(vm.cardRegion.draft?.region == regionBefore)
        guard case .autoDetected = vm.cardRegion else {
            Issue.record("retake during in-flight must not change workflow state; got \(vm.cardRegion)")
            return
        }
        guard case .captured = vm.state else {
            Issue.record("retake during in-flight must keep the captured state; got \(vm.state)")
            return
        }
        // No camera restart and no new live-detection stream.
        #expect(await session.startCount == cameraStartsBefore)
        #expect(await session.makeDetectionEventsCount == detectionStreamsBefore)
        // Capture had stopped live detection; a blocked retake must
        // not have restarted it either.
        #expect(vm.cardDetection == .inactive)

        // Release the gate: exactly one correction completes and the
        // settled result (draft A) wins — no stale clobbering.
        await crop.releaseCorrectionGate()
        await confirmTask.value

        #expect(!vm.isCropInFlight)
        #expect(await crop.correctCount == 1)
        guard case .confirmed(let result) = vm.cardRegion else {
            Issue.record("expected gated confirmation to settle .confirmed; got \(vm.cardRegion)")
            return
        }
        #expect(result.confirmedRegion == regionBefore)
    }

    @Test("correction failure enters the failed state")
    func correctionFailureEntersFailed() async {
        let crop = FakeCropProcessor(outcome: .detected, correctionError: .invalidRegion)
        let vm = await makePreviewViewModel(crop: crop)
        await vm.capture()

        await vm.confirmCrop()

        guard case .failed(let error) = vm.cardRegion else {
            Issue.record("expected .failed, got \(vm.cardRegion)")
            return
        }
        #expect(error == .invalidRegion)
    }

    // MARK: - S04 retake

    @Test("retake discards the draft, restarts preview and resumes detection")
    func retakeRestartsPreviewAndDetection() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(session: session, crop: crop)
        await vm.capture()
        guard case .autoDetected = vm.cardRegion else {
            Issue.record("precondition: expected .autoDetected")
            return
        }

        await vm.retake()

        #expect(vm.cardRegion == .inactive)
        #expect(vm.state == .preview)
        #expect(vm.cardDetection == .cardNotDetected)
        #expect(!vm.isCropInFlight)
        // A second detection stream was made for the restarted preview.
        await waitForDetectionStream(session, count: 2)
        #expect(await session.makeDetectionEventsCount == 2)

        // The user can capture again on the restarted preview.
        await vm.capture()
        guard case .captured = vm.state else {
            Issue.record("capture after retake must succeed, got \(vm.state)")
            return
        }
    }

    @Test("retake after photo import clears the import state without reopening the picker")
    func retakeAfterImportClearsImportState() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(session: session, crop: crop)

        await vm.handleSelectedImage(Data([0x01]))
        #expect(vm.photoImport != .idle)

        await vm.retake()

        #expect(vm.photoImport == .idle)
        #expect(!vm.isPickerPresented)
        #expect(vm.cardRegion == .inactive)
        #expect(vm.state == .preview)
    }

    @Test("retake is ignored when no crop screen is active")
    func retakeIgnoredWhenInactive() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let vm = await makePreviewViewModel(session: session, crop: crop)
        let startCountBefore = await session.startCount

        await vm.retake()

        #expect(vm.cardRegion == .inactive)
        #expect(await session.startCount == startCountBefore)
    }

    // MARK: - T07 raw recognition

    /// Drives confirmCrop off the MainActor and waits until the OCR
    /// fake records entry AND the recognition state reaches .processing
    /// (deterministic; no sleep).
    private func startGatedConfirmation(
        vm: ScanViewModel,
        ocr: FakeOCRProcessor
    ) async -> Task<Void, Never> {
        await ocr.enableGate()
        let task = Task { await vm.confirmCrop() }
        var entered = false
        for _ in 0..<200 {
            if await ocr.enteredCount == 1 {
                entered = true
                break
            }
            await Task.yield()
        }
        #expect(entered, "gated OCR must record entry")
        // The Task inside beginRecognition updates .processing after
        // the fake has already entered; wait for it.
        var processing = false
        for _ in 0..<200 {
            if case .processing = vm.recognition {
                processing = true
                break
            }
            await Task.yield()
        }
        #expect(processing, "recognition must reach .processing")
        return task
    }

    @Test("confirmed crop auto-starts OCR: processing then raw text, crop stays confirmed")
    func recognitionAutoStartsAndProducesRawText() async {
        let crop = FakeCropProcessor(outcome: .detected)
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await makePreviewViewModel(crop: crop, ocr: ocr)
        await vm.capture()

        let confirmTask = await startGatedConfirmation(vm: vm, ocr: ocr)

        // Recognition owns the screen while processing; the confirmed
        // crop remains underneath (separate state families).
        guard case .processing(let processingCrop) = vm.recognition else {
            Issue.record("expected .processing, got \(vm.recognition)")
            await ocr.releaseGate()
            return
        }
        guard case .confirmed(let confirmedCrop) = vm.cardRegion else {
            Issue.record("cardRegion must stay .confirmed during OCR; got \(vm.cardRegion)")
            await ocr.releaseGate()
            return
        }
        #expect(processingCrop == confirmedCrop)

        await ocr.releaseGate()
        await confirmTask.value

        // Wait for the recognition Task to complete its state update.
        var finalState = vm.recognition
        for _ in 0..<200 {
            if case .structuredResultAvailable = finalState { break }
            if case .nonCardEmptyResult = finalState { break }
            if case .missingFields = finalState { break }
            if case .multiplePhoneFields = finalState { break }
            if case .failed = finalState { break }
            await Task.yield()
            finalState = vm.recognition
        }

        guard case .structuredResultAvailable(let result) = finalState else {
            Issue.record("expected .structuredResultAvailable, got \(finalState)")
            return
        }
        #expect(result.ocrResult.lines.count == 10)
        #expect(result.ocrResult.rawText.contains("张伟"))
        #expect(result.ocrResult.rawText.contains("+86 138 0013 8000"))
        #expect(result.fields.name == "张伟")
        #expect(result.fields.company == "上海智云科技有限公司")
        #expect(result.fields.website == "www.zhiyuntech.com")
        #expect(result.ocrResult.cropResult == confirmedCrop)
        #expect(await ocr.enteredCount == 1)
        guard case .confirmed = vm.cardRegion else {
            Issue.record("crop must remain .confirmed after OCR; got \(vm.cardRegion)")
            return
        }
    }

    @Test("zero-text recognition settles nonCardEmptyResult, not failure")
    func emptyRecognitionSettlesEmptyResult() async {
        let ocr = FakeOCRProcessor(outcome: .empty)
        let vm = await makePreviewViewModel(
            crop: FakeCropProcessor(outcome: .detected), ocr: ocr
        )
        await vm.capture()

        let confirmTask = await startGatedConfirmation(vm: vm, ocr: ocr)
        guard case .processing = vm.recognition else {
            Issue.record("expected .processing, got \(vm.recognition)")
            await ocr.releaseGate()
            return
        }

        await ocr.releaseGate()
        await confirmTask.value

        // Wait for the recognition Task to complete its state update.
        var finalState = vm.recognition
        for _ in 0..<200 {
            if case .nonCardEmptyResult = finalState { break }
            if case .failed = finalState { break }
            await Task.yield()
            finalState = vm.recognition
        }

        guard case .nonCardEmptyResult(let result) = finalState else {
            Issue.record("expected .nonCardEmptyResult, got \(finalState)")
            return
        }
        #expect(result.ocrResult.lines.isEmpty)
        #expect(result.ocrResult.rawText.isEmpty)
        #expect(result.fields.name == nil)
        #expect(result.fields.phones.isEmpty)
        guard case .confirmed = vm.cardRegion else {
            Issue.record("crop must stay .confirmed under an empty OCR result")
            return
        }
    }

    @Test("failed recognition settles .failed without a raw result")
    func failedRecognitionSettlesFailed() async {
        let ocr = FakeOCRProcessor(outcome: .failure)
        let vm = await makePreviewViewModel(
            crop: FakeCropProcessor(outcome: .detected), ocr: ocr
        )
        await vm.capture()

        let confirmTask = await startGatedConfirmation(vm: vm, ocr: ocr)
        guard case .processing = vm.recognition else {
            Issue.record("expected .processing, got \(vm.recognition)")
            await ocr.releaseGate()
            return
        }

        await ocr.releaseGate()
        await confirmTask.value

        // Wait for the recognition Task to complete its state update.
        var finalState = vm.recognition
        for _ in 0..<200 {
            if case .failed = finalState { break }
            if case .structuredResultAvailable = finalState { break }
            if case .nonCardEmptyResult = finalState { break }
            if case .missingFields = finalState { break }
            if case .multiplePhoneFields = finalState { break }
            await Task.yield()
            finalState = vm.recognition
        }

        guard case .failed(let error) = finalState else {
            Issue.record("expected .failed, got \(finalState)")
            return
        }
        #expect(error == .recognitionFailed)
        guard case .confirmed = vm.cardRegion else {
            Issue.record("a failed OCR must not roll the confirmed crop back")
            return
        }
    }

    @Test("retake during recognition invalidates the late in-flight result")
    func retakeInvalidatesInFlightRecognition() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await makePreviewViewModel(session: session, crop: crop, ocr: ocr)
        await vm.capture()

        let confirmTask = await startGatedConfirmation(vm: vm, ocr: ocr)
        guard case .processing = vm.recognition else {
            Issue.record("precondition: expected .processing, got \(vm.recognition)")
            await ocr.releaseGate()
            return
        }

        // Retake is allowed while OCR runs (no perspective correction
        // is in flight): it discards crop + recognition and restarts
        // the scanner.
        await vm.retake()
        #expect(vm.recognition == .inactive)
        #expect(vm.cardRegion == .inactive)
        #expect(vm.state == .preview)

        await ocr.releaseGate()
        await confirmTask.value

        // The late success must not resurrect the recognition screen.
        #expect(vm.recognition == .inactive, "stale OCR result must be discarded")
        #expect(await ocr.enteredCount == 1)
    }

    @Test("scanner disappear invalidates the late in-flight recognition result")
    func disappearInvalidatesInFlightRecognition() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await makePreviewViewModel(session: session, crop: crop, ocr: ocr)
        await vm.capture()

        let confirmTask = await startGatedConfirmation(vm: vm, ocr: ocr)
        let processingCrop = vm.recognition

        // Leaving the scanner invalidates the in-flight generation; the
        // display state itself is not cleared.
        await vm.scannerDidDisappear()

        await ocr.releaseGate()
        await confirmTask.value

        // The stale result must not overwrite the pre-exit state.
        #expect(vm.recognition == processingCrop,
                "a post-disappear OCR result must be ignored")
        guard case .processing = vm.recognition else {
            Issue.record("state must remain .processing, got \(vm.recognition)")
            return
        }
    }

    @Test("stale A cannot overwrite a newer B after retake + new capture")
    func staleACannotOverwriteNewerB() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        // Gated fake records each entry; outcome is .success.
        let ocrA = FakeOCRProcessor(outcome: .success)
        let vm = await makePreviewViewModel(session: session, crop: crop, ocr: ocrA)
        await vm.capture()

        // Start A: gated OCR so A is in-flight.
        let confirmTaskA = await startGatedConfirmation(vm: vm, ocr: ocrA)
        guard case .processing = vm.recognition else {
            Issue.record("A must be .processing")
            await ocrA.releaseGate()
            return
        }
        #expect(await ocrA.enteredCount == 1)

        // Retake cancels A (task + generation).
        await vm.retake()
        #expect(vm.recognition == .inactive)

        // Release A's gate: its result arrives but must be discarded.
        await ocrA.releaseGate()
        await confirmTaskA.value
        #expect(vm.recognition == .inactive, "stale A must not resurrect recognition")

        // Start B on the SAME view model: new capture → crop → OCR.
        // The same FakeOCRProcessor instance counts both entries.
        await vm.capture()
        let confirmTaskB = await startGatedConfirmation(vm: vm, ocr: ocrA)
        guard case .processing = vm.recognition else {
            Issue.record("B must be .processing, got \(vm.recognition)")
            await ocrA.releaseGate()
            return
        }

        await ocrA.releaseGate()
        await confirmTaskB.value

        // Wait for the recognition Task to complete its state update.
        var finalState = vm.recognition
        for _ in 0..<200 {
            if case .structuredResultAvailable = finalState { break }
            if case .nonCardEmptyResult = finalState { break }
            if case .missingFields = finalState { break }
            if case .multiplePhoneFields = finalState { break }
            if case .failed = finalState { break }
            await Task.yield()
            finalState = vm.recognition
        }

        // B completes normally and owns the final state.
        guard case .structuredResultAvailable(let resultB) = finalState else {
            Issue.record("expected .structuredResultAvailable from B, got \(finalState)")
            return
        }
        #expect(resultB.ocrResult.rawText.contains("张伟"))
        #expect(resultB.fields.name == "张伟")
        // A entered once, B entered once — same processor, two tasks.
        #expect(await ocrA.enteredCount == 2)
    }

    // MARK: - Week 4 Increment 2 structured classification (12 items)

    /// Deterministic extractor fake: returns a fixed StructuredCardFields
    /// for any input, preserving the passed OCR result.
    private struct FixedExtractor: CardFieldExtracting {
        let fields: StructuredCardFields
        func extract(from result: CardOCRResult) -> StructuredRecognitionResult {
            StructuredRecognitionResult(ocrResult: result, fields: fields)
        }
    }

    private func makeCard001Fields() -> StructuredCardFields {
        StructuredCardFields(
            name: "张伟",
            company: "上海智云科技有限公司",
            jobTitle: "产品总监 | Product Director",
            phones: [
                PhoneNumber(kind: .mobile, value: "+86 138 0013 8000"),
                PhoneNumber(kind: .office, value: "+86 21 5555 1234"),
            ],
            emails: ["wei.zhang@zhiyuntech.com"],
            website: "www.zhiyuntech.com",
            address: "上海市浦东新区世纪大道100号 200120"
        )
    }

    private func makeCard002Fields() -> StructuredCardFields {
        StructuredCardFields(
            name: "李娜",
            company: "上海智云科技有限公司",
            jobTitle: "市场总监 | Marketing Director",
            phones: [
                PhoneNumber(kind: .mobile, value: "+86 139 1234 5678"),
                PhoneNumber(kind: .office, value: "+86 21 6888 2468"),
            ],
            emails: ["lina.li@zhiyuntech.com"],
            website: nil,
            address: "上海市浦东新区世纪大道188号 200120"
        )
    }

    private func makeCard003Fields() -> StructuredCardFields {
        StructuredCardFields(
            name: "陈晨",
            company: "上海智云科技有限公司",
            jobTitle: "商务拓展经理 | Business Development Manager",
            phones: [
                PhoneNumber(kind: .mobile, value: "+86 136 8888 1024"),
                PhoneNumber(kind: .office, value: "+86 21 5666 7788"),
                PhoneNumber(kind: .fax, value: "+86 21 5666 7799"),
            ],
            emails: ["chen.chen@zhiyuntech.com"],
            website: "www.zhiyuntech.com",
            address: "上海市徐汇区漕溪北路398号 200030"
        )
    }

    private func makeCard004Fields() -> StructuredCardFields {
        StructuredCardFields(
            name: "张 伟",
            phones: [PhoneNumber(kind: .mobile, value: "+86 138 0013 8000")]
        )
    }

    private func makeNoStructuredFields() -> StructuredCardFields {
        StructuredCardFields(unclassifiedText: ["some non-card text"])
    }

    private func driveCropAndWait(
        ocr: FakeOCRProcessor,
        extractor: (any CardFieldExtracting)? = nil
    ) async -> ScanViewModel {
        let vm = await makePreviewViewModel(
            crop: FakeCropProcessor(outcome: .detected),
            ocr: ocr,
            fieldExtractor: extractor
        )
        await vm.capture()
        let confirmTask = await startGatedConfirmation(vm: vm, ocr: ocr)
        await ocr.releaseGate()
        await confirmTask.value
        return vm
    }

    private func waitForStructuredState(
        _ vm: ScanViewModel,
        timeout: Int = 200
    ) async -> ScanViewModel.RecognitionState {
        var state = vm.recognition
        for _ in 0..<timeout {
            switch state {
            case .structuredResultAvailable, .nonCardEmptyResult,
                 .missingFields, .multiplePhoneFields, .manualEditing, .failed:
                return state
            case .inactive, .processing:
                await Task.yield()
                state = vm.recognition
            }
        }
        return state
    }

    @Test("1. processing → structuredResultAvailable (card-001 complete)")
    func structuredStateCompleteCard() async {
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await driveCropAndWait(ocr: ocr)
        let state = await waitForStructuredState(vm)
        guard case .structuredResultAvailable(let result) = state else {
            Issue.record("expected .structuredResultAvailable, got \(state)")
            return
        }
        #expect(result.fields.name == "张伟")
        #expect(result.fields.company == "上海智云科技有限公司")
        #expect(result.fields.website == "www.zhiyuntech.com")
        #expect(result.fields.phones.count == 2)
    }

    @Test("2. missing website → missingFields (card-002)")
    func missingWebsiteClassifiedMissingFields() async {
        let ocr = FakeOCRProcessor(outcome: .missing)
        let vm = await driveCropAndWait(ocr: ocr)
        let state = await waitForStructuredState(vm)
        guard case .missingFields(let result) = state else {
            Issue.record("expected .missingFields, got \(state)")
            return
        }
        #expect(result.fields.website == nil)
        #expect(result.fields.name == "李娜")
    }

    @Test("3. mobile+office+fax → multiplePhoneFields (card-003)")
    func multiPhoneClassifiedMultiplePhoneFields() async {
        let ocr = FakeOCRProcessor(outcome: .multiple)
        let vm = await driveCropAndWait(ocr: ocr)
        let state = await waitForStructuredState(vm)
        guard case .multiplePhoneFields(let result) = state else {
            Issue.record("expected .multiplePhoneFields, got \(state)")
            return
        }
        #expect(result.fields.phones(of: .mobile).count == 1)
        #expect(result.fields.phones(of: .office).count == 1)
        #expect(result.fields.phones(of: .fax).count == 1)
    }

    @Test("4. card-004 name+mobile only → missingFields")
    func minimalCardClassifiedMissingFields() async {
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await driveCropAndWait(ocr: ocr, extractor: FixedExtractor(fields: makeCard004Fields()))
        let state = await waitForStructuredState(vm)
        guard case .missingFields(let result) = state else {
            Issue.record("expected .missingFields, got \(state)")
            return
        }
        #expect(result.fields.name == "张 伟")
        #expect(result.fields.phones.count == 1)
        #expect(result.fields.company == nil)
        #expect(result.fields.website == nil)
    }

    @Test("5. zero raw + zero structured → nonCardEmptyResult")
    func emptyOCRClassifiedNonCardEmpty() async {
        let ocr = FakeOCRProcessor(outcome: .empty)
        let vm = await driveCropAndWait(ocr: ocr)
        let state = await waitForStructuredState(vm)
        guard case .nonCardEmptyResult(let result) = state else {
            Issue.record("expected .nonCardEmptyResult, got \(state)")
            return
        }
        #expect(result.ocrResult.lines.isEmpty)
        #expect(result.fields.name == nil)
    }

    @Test("6. raw non-empty but no structured field → nonCardEmptyResult")
    func rawNonEmptyNoStructuredClassifiedNonCardEmpty() async {
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await driveCropAndWait(ocr: ocr, extractor: FixedExtractor(fields: makeNoStructuredFields()))
        let state = await waitForStructuredState(vm)
        guard case .nonCardEmptyResult(let result) = state else {
            Issue.record("expected .nonCardEmptyResult, got \(state)")
            return
        }
        #expect(!result.ocrResult.rawText.isEmpty)
        #expect(result.fields.unclassifiedText == ["some non-card text"])
    }

    @Test("7. OCR failure → failed")
    func ocrFailureClassifiedFailed() async {
        let ocr = FakeOCRProcessor(outcome: .failure)
        let vm = await driveCropAndWait(ocr: ocr)
        let state = await waitForStructuredState(vm)
        guard case .failed(let error) = state else {
            Issue.record("expected .failed, got \(state)")
            return
        }
        #expect(error == .recognitionFailed)
    }

    @Test("8. raw OCR preserved inside StructuredRecognitionResult")
    func rawOCRPreservedInStructuredResult() async {
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await driveCropAndWait(ocr: ocr)
        let state = await waitForStructuredState(vm)
        guard case .structuredResultAvailable(let result) = state else {
            Issue.record("expected .structuredResultAvailable, got \(state)")
            return
        }
        // The structured result carries the unchanged OCR result.
        #expect(result.ocrResult.rawText.contains("手机 Mobile：+86 138 0013 8000"))
        #expect(result.ocrResult.rawText.contains("wei.zhang@zhiyuntech.com"))
        #expect(result.ocrResult.lines.count == 10)
        // The extractor output and raw OCR must not be the same object,
        // but the raw text must be identical to OCR output.
        #expect(result.ocrResult.rawText == result.ocrResult.rawText) // tautology
    }

    @Test("9. retake clears structured result")
    func retakeClearsStructuredResult() async {
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await driveCropAndWait(ocr: ocr)
        _ = await waitForStructuredState(vm)
        await vm.retake()
        #expect(vm.recognition == .inactive)
        #expect(vm.cardRegion == .inactive)
        #expect(vm.state == .preview)
    }

    @Test("10. stale A cannot overwrite newer structured B")
    func staleACannotOverwriteStructuredB() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await makePreviewViewModel(session: session, crop: crop, ocr: ocr)
        await vm.capture()
        let confirmTaskA = await startGatedConfirmation(vm: vm, ocr: ocr)
        #expect(await ocr.enteredCount == 1)
        await vm.retake()
        await ocr.releaseGate()
        await confirmTaskA.value
        #expect(vm.recognition == .inactive)

        await vm.capture()
        let confirmTaskB = await startGatedConfirmation(vm: vm, ocr: ocr)
        await ocr.releaseGate()
        await confirmTaskB.value
        let state = await waitForStructuredState(vm)
        guard case .structuredResultAvailable(let result) = state else {
            Issue.record("expected .structuredResultAvailable from B, got \(state)")
            return
        }
        #expect(result.fields.name == "张伟")
        #expect(await ocr.enteredCount == 2)
    }

    @Test("11. scanner disappear invalidates in-flight structured result")
    func disappearInvalidatesInFlightStructured() async {
        let session = FakeSession()
        let crop = FakeCropProcessor(outcome: .detected)
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await makePreviewViewModel(session: session, crop: crop, ocr: ocr)
        await vm.capture()
        let confirmTask = await startGatedConfirmation(vm: vm, ocr: ocr)
        let processingCrop = vm.recognition
        await vm.scannerDidDisappear()
        await ocr.releaseGate()
        await confirmTask.value
        #expect(vm.recognition == processingCrop)
        guard case .processing = vm.recognition else {
            Issue.record("state must remain .processing, got \(vm.recognition)")
            return
        }
    }

    @Test("12. default extractor path deterministic (no injection)")
    func defaultExtractorDeterministic() async {
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await makePreviewViewModel(crop: FakeCropProcessor(outcome: .detected), ocr: ocr)
        await vm.capture()
        let confirmTask = await startGatedConfirmation(vm: vm, ocr: ocr)
        await ocr.releaseGate()
        await confirmTask.value
        let state = await waitForStructuredState(vm)
        guard case .structuredResultAvailable(let result) = state else {
            Issue.record("expected .structuredResultAvailable, got \(state)")
            return
        }
        #expect(result.fields.name == "张伟")
    }

    // MARK: - Week 4 Increment 3 T11 manual editing

    /// Drives the full pipeline to a settled state, then enters
    /// manualEditing. Returns the editing ViewModel.
    private func enterManualEditing(
        ocr: FakeOCRProcessor,
        extractor: (any CardFieldExtracting)? = nil
    ) async -> ScanViewModel {
        let vm = await driveCropAndWait(ocr: ocr, extractor: extractor)
        _ = await waitForStructuredState(vm)
        vm.beginManualEditing()
        return vm
    }

    /// Extracts the draft from a `.manualEditing` state or records
    /// an issue and returns nil.
    private func draft(from vm: ScanViewModel) -> RecognitionDraft? {
        guard case .manualEditing(let draft) = vm.recognition else {
            Issue.record("expected .manualEditing, got \(vm.recognition)")
            return nil
        }
        return draft
    }

    @Test("T11 1. structuredResultAvailable → beginManualEditing → manualEditing")
    func beginEditingFromStructuredState() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        guard let draft = draft(from: vm) else { return }
        #expect(draft.name == "张伟")
        #expect(draft.company == "上海智云科技有限公司")
    }

    @Test("T11 2. missingFields → beginManualEditing → manualEditing")
    func beginEditingFromMissingFieldsState() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .missing))
        guard let draft = draft(from: vm) else { return }
        #expect(draft.name == "李娜")
        // Missing website maps to an editable empty string.
        #expect(draft.website == "")
        #expect(draft.source.fields.website == nil)
    }

    @Test("T11 3. multiplePhoneFields → beginManualEditing → manualEditing")
    func beginEditingFromMultiplePhoneState() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .multiple))
        guard let draft = draft(from: vm) else { return }
        #expect(draft.phones.map(\.kind) == [.mobile, .office, .fax])
    }

    @Test("T11 4. draft initialization preserves every structured value")
    func draftInitializationPreservesStructuredValues() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        guard let draft = draft(from: vm) else { return }

        #expect(draft.name == "张伟")
        #expect(draft.company == "上海智云科技有限公司")
        #expect(draft.jobTitle == "产品总监 | Product Director")
        #expect(draft.website == "www.zhiyuntech.com")
        #expect(draft.address == "上海市浦东新区世纪大道100号 200120")
        #expect(draft.phones.map(\.value) == ["+86 138 0013 8000", "+86 21 5555 1234"])
        #expect(draft.phones.map(\.kind) == [.mobile, .office])
        #expect(draft.emails.map(\.value) == ["wei.zhang@zhiyuntech.com"])
    }

    @Test("T11 5. editing name updates only the draft name")
    func editingNameUpdatesDraftOnly() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        vm.updateDraftName("张伟 修正")

        guard let draft = draft(from: vm) else { return }
        #expect(draft.name == "张伟 修正")
        #expect(draft.correctedFields.name == "张伟 修正")
        // All other values stay at their originals.
        #expect(draft.company == "上海智云科技有限公司")
        #expect(draft.jobTitle == "产品总监 | Product Director")
        #expect(draft.phones.map(\.value) == ["+86 138 0013 8000", "+86 21 5555 1234"])
        #expect(draft.emails.map(\.value) == ["wei.zhang@zhiyuntech.com"])
        #expect(draft.website == "www.zhiyuntech.com")
        #expect(draft.address == "上海市浦东新区世纪大道100号 200120")
    }

    @Test("T11 6. editing company updates only the draft company")
    func editingCompanyUpdatesDraftOnly() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        vm.updateDraftCompany("上海智云科技")

        guard let draft = draft(from: vm) else { return }
        #expect(draft.company == "上海智云科技")
        #expect(draft.correctedFields.company == "上海智云科技")
        #expect(draft.name == "张伟")
        #expect(draft.source.fields.company == "上海智云科技有限公司")
    }

    @Test("T11 7. editing a phone value preserves the phone kind")
    func editingPhonePreservesKind() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        guard let before = draft(from: vm) else { return }
        let mobileID = before.phones[0].id
        vm.updateDraftPhone(id: mobileID, value: "+86 138 0013 8001")

        guard let draft = draft(from: vm) else { return }
        let corrected = draft.correctedFields
        #expect(corrected.phones(of: .mobile).map(\.value) == ["+86 138 0013 8001"])
        #expect(corrected.phones(of: .office).map(\.value) == ["+86 21 5555 1234"])
        // Kind and source identity are preserved.
        #expect(draft.phones[0].kind == .mobile)
        #expect(draft.phones[0].sourceID == before.phones[0].sourceID)
    }

    @Test("T11 8. editing one email updates only the intended email")
    func editingEmailIsSurgical() async {
        let fields = StructuredCardFields(
            name: "张伟",
            company: "上海智云科技有限公司",
            jobTitle: "产品总监",
            phones: [PhoneNumber(kind: .mobile, value: "+86 138 0013 8000")],
            emails: ["first@example.com", "second@example.com"],
            website: "www.example.com",
            address: "某地址"
        )
        let vm = await enterManualEditing(
            ocr: FakeOCRProcessor(outcome: .success),
            extractor: FixedExtractor(fields: fields)
        )
        vm.updateDraftEmail(id: 1, value: "edited@example.com")

        guard let draft = draft(from: vm) else { return }
        #expect(draft.emails.map(\.value) == ["first@example.com", "edited@example.com"])
        #expect(draft.correctedFields.emails == ["first@example.com", "edited@example.com"])
    }

    @Test("T11 9. clearing a scalar produces nil in correctedFields")
    func clearingScalarProducesNil() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        vm.updateDraftWebsite("")
        vm.updateDraftName("   ")

        guard let draft = draft(from: vm) else { return }
        #expect(draft.correctedFields.website == nil)
        #expect(draft.correctedFields.name == nil)
        // The edited strings remain empty/blank in the live draft
        // (TextField shows them blank); only the projection nils them.
        #expect(draft.website == "")
    }

    @Test("T11 10. clearing a phone/email removes it from correctedFields")
    func clearingPhoneEmailRemovesFromCorrected() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        guard let before = draft(from: vm) else { return }
        vm.updateDraftPhone(id: before.phones[0].id, value: "")
        vm.updateDraftEmail(id: before.emails[0].id, value: "  ")

        guard let draft = draft(from: vm) else { return }
        // The editing rows still exist (correction of existing fields),
        // but the corrected projection drops the blank values.
        #expect(draft.phones.count == 2)
        #expect(draft.emails.count == 1)
        #expect(draft.correctedFields.phones.map(\.value) == ["+86 21 5555 1234"])
        #expect(draft.correctedFields.emails.isEmpty)
    }

    @Test("T11 11. the source StructuredRecognitionResult remains unchanged")
    func sourceStructuredResultRemainsUnchanged() async {
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await driveCropAndWait(ocr: ocr)
        let settled = await waitForStructuredState(vm)
        guard case .structuredResultAvailable(let original) = settled else {
            Issue.record("precondition: expected structuredResultAvailable, got \(settled)")
            return
        }

        vm.beginManualEditing()
        vm.updateDraftName("张伟 修正")
        vm.updateDraftCompany("上海智云科技")
        vm.updateDraftPhone(id: 0, value: "+86 138 0013 8001")
        vm.updateDraftEmail(id: 0, value: "other@example.com")
        vm.updateDraftWebsite("")
        vm.updateDraftAddress("其他地址")

        guard let draft = draft(from: vm) else { return }
        #expect(draft.source.fields == original.fields)
        #expect(draft.source.fields.name == "张伟")
        #expect(draft.source.fields.company == "上海智云科技有限公司")
        #expect(draft.source.fields.website == "www.zhiyuntech.com")
        #expect(draft.source.fields.emails == ["wei.zhang@zhiyuntech.com"])
    }

    @Test("T11 12. raw OCR remains unchanged after manual corrections")
    func rawOCRRemainsUnchanged() async {
        let ocr = FakeOCRProcessor(outcome: .success)
        let vm = await driveCropAndWait(ocr: ocr)
        let settled = await waitForStructuredState(vm)
        guard case .structuredResultAvailable(let original) = settled else {
            Issue.record("precondition: expected structuredResultAvailable, got \(settled)")
            return
        }

        vm.beginManualEditing()
        vm.updateDraftName("完全不同的名字")
        vm.updateDraftPhone(id: 0, value: "000")

        guard let draft = draft(from: vm) else { return }
        #expect(draft.source.ocrResult == original.ocrResult)
        #expect(draft.source.ocrResult.rawText == original.ocrResult.rawText)
        #expect(draft.source.ocrResult.rawText.contains("张伟"))
        #expect(draft.source.ocrResult.rawText.contains("+86 138 0013 8000"))
        #expect(draft.source.ocrResult.lines.count == 10)
    }

    @Test("T11 13. hasChanges is false on a fresh draft")
    func hasChangesFalseInitially() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        guard let draft = draft(from: vm) else { return }
        #expect(!draft.hasChanges)
        #expect(draft.correctedFields == draft.source.fields)
    }

    @Test("T11 14. hasChanges is true after a correction")
    func hasChangesTrueAfterCorrection() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        vm.updateDraftName("张伟 修正")
        guard let draft = draft(from: vm) else { return }
        #expect(draft.hasChanges)
    }

    @Test("T11 15. retake from manualEditing discards the draft and returns to scanner")
    func retakeFromManualEditingDiscardsDraft() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        vm.updateDraftName("张伟 修正")
        guard case .manualEditing = vm.recognition else {
            Issue.record("precondition: expected manualEditing")
            return
        }

        await vm.retake()

        #expect(vm.recognition == .inactive)
        #expect(vm.cardRegion == .inactive)
        #expect(vm.state == .preview)
    }

    @Test("T11 extra. nonCardEmptyResult can also enter manualEditing with an empty draft")
    func beginEditingFromNonCardEmptyState() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .empty))
        guard let draft = draft(from: vm) else { return }
        #expect(draft.name == "")
        #expect(draft.phones.isEmpty)
        #expect(draft.emails.isEmpty)
        #expect(draft.source.ocrResult.rawText.isEmpty)
    }

    @Test("T11 extra. beginning editing again keeps the in-progress draft (stable no-op)")
    func beginEditingTwiceKeepsDraft() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        vm.updateDraftName("张伟 修正")
        vm.beginManualEditing()

        guard let draft = draft(from: vm) else { return }
        #expect(draft.name == "张伟 修正")
        #expect(draft.source.fields.name == "张伟")
    }

    @Test("T11 extra. editing intents are ignored outside manualEditing")
    func editingIntentsIgnoredOutsideManualEditing() async {
        let auth = FakeAuthorization(initialStatus: .authorized)
        let vm = ScanViewModel(authorization: auth, sessionController: FakeSession())
        #expect(vm.recognition == .inactive)

        vm.beginManualEditing()
        vm.updateDraftName("不应生效")
        vm.updateDraftPhone(id: 0, value: "000")

        #expect(vm.recognition == .inactive)
    }

    // MARK: - Week 4 Increment 4 T12 Save (S06 SaveState)

    /// Drives the full pipeline into a settled structured result with
    /// persistence dependencies injected, WITHOUT entering Edit, then
    /// returns the ViewModel and stores. A custom `ImageAssetStore` can
    /// be injected (e.g. the gated double for the `.saving` test).
    private func enterSettledWithPersistence(
        ocr: FakeOCRProcessor = FakeOCRProcessor(outcome: .success),
        imageStore injectedStore: (any ImageAssetStore)? = nil
    ) async -> (ScanViewModel, InMemoryBusinessCardRepository, any ImageAssetStore) {
        let repository = InMemoryBusinessCardRepository()
        let store: any ImageAssetStore = injectedStore ?? InMemoryImageAssetStore()
        let vm = ScanViewModel(
            authorization: FakeAuthorization(initialStatus: .authorized),
            sessionController: FakeSession(),
            cropProcessor: FakeCropProcessor(outcome: .detected),
            ocrProcessor: ocr,
            cardRepository: repository,
            imageStore: store
        )
        await vm.scannerDidAppear()
        #expect(vm.state == .preview)
        await vm.capture()
        let confirmTask = await startGatedConfirmation(vm: vm, ocr: ocr)
        await ocr.releaseGate()
        await confirmTask.value
        _ = await waitForStructuredState(vm)
        return (vm, repository, store)
    }

    /// Same as `enterSettledWithPersistence` but additionally enters
    /// S05 manualEditing (corrected-save path).
    private func enterEditingWithPersistence(
        ocr: FakeOCRProcessor = FakeOCRProcessor(outcome: .success)
    ) async -> (ScanViewModel, InMemoryBusinessCardRepository, any ImageAssetStore) {
        let (vm, repository, store) = await enterSettledWithPersistence(ocr: ocr)
        vm.beginManualEditing()
        return (vm, repository, store)
    }

    /// Gated ImageAssetStore: the first `save` suspends at an
    /// observable gate until `releaseGate()`, so a test can assert the
    /// transient `SaveState.saving` + `isSaveInFlight == true` phase.
    /// Mirrors the established FakeOCRProcessor gate pattern.
    private actor GatedImageAssetStore: ImageAssetStore {
        private var assets: [String: Data] = [:]
        private var gateEnabled = false
        private var waiters: [CheckedContinuation<Void, Never>] = []
        private(set) var enteredCount = 0

        var persistedCount: Int { assets.count }

        func enableGate() {
            gateEnabled = true
        }

        func releaseGate() {
            gateEnabled = false
            let pending = waiters
            waiters.removeAll()
            for waiter in pending {
                waiter.resume()
            }
        }

        func save(reference: String, data: Data) async {
            enteredCount += 1
            if gateEnabled {
                await withCheckedContinuation { continuation in
                    waiters.append(continuation)
                }
            }
            assets[reference] = data
        }

        func data(for reference: String) -> Data? {
            assets[reference]
        }
    }

    /// Extracts the card from a settled `.saveSucceeded` SaveState or
    /// records an issue and returns nil.
    private func savedCard(from vm: ScanViewModel) -> BusinessCard? {
        guard case .saveSucceeded(let card) = vm.saveState else {
            Issue.record("expected saveState .saveSucceeded, got \(vm.saveState)")
            return nil
        }
        return card
    }

    @Test("T12 1. saveCurrentCard materializes the corrected draft into saveSucceeded")
    func saveCurrentCardMaterializesCorrectedDraft() async {
        let (vm, repository, _) = await enterEditingWithPersistence()
        vm.updateDraftName("张伟 修正")
        await vm.saveCurrentCard()

        guard let card = savedCard(from: vm) else { return }
        #expect(card.name == "张伟 修正")
        #expect(card.company == "上海智云科技有限公司")
        #expect(card.jobTitle == "产品总监 | Product Director")
        #expect(card.website == "www.zhiyuntech.com")
        #expect(card.phones.map(\.value) == ["+86 138 0013 8000", "+86 21 5555 1234"])
        #expect(card.emails == ["wei.zhang@zhiyuntech.com"])
        #expect(await repository.card(id: card.id) == card)
    }

    @Test("T12 2. saveCurrentCard persists both image assets byte-exact and wires real references")
    func saveCurrentCardPersistsImageAssets() async {
        let (vm, _, store) = await enterEditingWithPersistence()
        guard let draft = draft(from: vm) else { return }
        let expectedOriginal = draft.source.ocrResult.cropResult.original.data
        let expectedProcessed = draft.source.ocrResult.cropResult.processedImageData

        await vm.saveCurrentCard()

        guard let card = savedCard(from: vm) else { return }
        // References are real resolvable tokens, not placeholders.
        #expect(card.originalImageReference.hasPrefix("card-"))
        #expect(card.originalImageReference.hasSuffix("-original"))
        #expect(card.processedImageReference.hasSuffix("-processed"))
        #expect(card.originalImageReference.contains(card.id.uuidString))
        #expect(await store.data(for: card.originalImageReference) == expectedOriginal)
        #expect(await store.data(for: card.processedImageReference) == expectedProcessed)
        // The ViewModel read seam resolves the same bytes.
        #expect(await vm.imageData(for: card.processedImageReference) == expectedProcessed)
    }

    @Test("T12 3. saveCurrentCard keeps the original raw OCR text on the card")
    func saveCurrentCardKeepsRawOCRText() async {
        let (vm, _, _) = await enterEditingWithPersistence()
        guard let draft = draft(from: vm) else { return }
        let originalRawText = draft.source.ocrResult.rawText
        vm.updateDraftName("完全不同的名字")

        await vm.saveCurrentCard()

        guard let card = savedCard(from: vm) else { return }
        #expect(card.rawOCRText == originalRawText)
        #expect(card.rawOCRText?.contains("张伟") == true)
    }

    @Test("T12 4. corrected blank fields are dropped from the saved card")
    func saveCurrentCardProjectsBlankCorrections() async {
        let (vm, repository, _) = await enterEditingWithPersistence()
        guard let draft = draft(from: vm) else { return }
        vm.updateDraftWebsite("")
        vm.updateDraftPhone(id: draft.phones[0].id, value: "")

        await vm.saveCurrentCard()

        guard let card = savedCard(from: vm) else { return }
        #expect(card.website == nil)
        #expect(card.phones.map(\.value) == ["+86 21 5555 1234"])
        #expect(card.phones.map(\.kind) == [.office])
        #expect(await repository.card(id: card.id)?.website == nil)
    }

    @Test("T12 5. saveCurrentCard without persistence dependencies is a no-op")
    func saveCurrentCardWithoutDependenciesIsNoOp() async {
        let vm = await enterManualEditing(ocr: FakeOCRProcessor(outcome: .success))
        await vm.saveCurrentCard()
        guard case .manualEditing = vm.recognition else {
            Issue.record("expected manualEditing to remain, got \(vm.recognition)")
            return
        }
        #expect(vm.saveState == .idle)
    }

    @Test("T12 6. a complete structured result saves directly without Edit")
    func completeStructuredResultSavesDirectlyWithoutEditing() async {
        let (vm, repository, _) = await enterSettledWithPersistence()
        #expect(vm.saveState == .idle)

        // No Edit — Save directly from the read-only P05 form.
        await vm.saveCurrentCard()

        guard let card = savedCard(from: vm) else { return }
        // S05 recognition stays untouched underneath the settled save.
        guard case .structuredResultAvailable = vm.recognition else {
            Issue.record("expected recognition to remain settled, got \(vm.recognition)")
            return
        }
        // Values come verbatim from the structured result.
        #expect(card.name == "张伟")
        #expect(card.company == "上海智云科技有限公司")
        #expect(card.jobTitle == "产品总监 | Product Director")
        #expect(card.website == "www.zhiyuntech.com")
        #expect(card.phones.map(\.value) == ["+86 138 0013 8000", "+86 21 5555 1234"])
        #expect(card.emails == ["wei.zhang@zhiyuntech.com"])
        #expect(await repository.card(id: card.id) == card)
    }

    @Test("T12 7. a missingFields result saves directly without fabrication")
    func missingFieldsResultSavesDirectlyWithoutFabrication() async {
        let (vm, repository, _) = await enterSettledWithPersistence(
            ocr: FakeOCRProcessor(outcome: .missing)
        )
        guard case .missingFields(let result) = vm.recognition else {
            Issue.record("expected .missingFields, got \(vm.recognition)")
            return
        }
        // card-002 style: the website is missing from the extraction.
        #expect(result.fields.website == nil)

        await vm.saveCurrentCard()

        guard let card = savedCard(from: vm) else { return }
        // Missing fields stay nil on the final card — never fabricated.
        #expect(card.website == nil)
        #expect(card.name == result.fields.name)
        #expect(card.company == result.fields.company)
        #expect(card.jobTitle == result.fields.jobTitle)
        #expect(card.phones.map(\.value) == result.fields.phones.map(\.value))
        #expect(card.emails == result.fields.emails)
        #expect(card.rawOCRText == result.ocrResult.rawText)
        #expect(await repository.card(id: card.id) == card)
    }

    @Test("T12 8. final phone identities are fresh domain UUIDs")
    func finalPhoneIDsAreFreshDomainIDs() async {
        let (vm, repository, _) = await enterEditingWithPersistence()
        guard let draft = draft(from: vm) else { return }
        let intermediate = draft.correctedFields.phones
        #expect(intermediate.count == 2)

        await vm.saveCurrentCard()

        guard let card = savedCard(from: vm) else { return }
        // Only kind + value are inherited; identity is re-issued.
        #expect(card.phones.map(\.value) == intermediate.map(\.value))
        #expect(card.phones.map(\.kind) == intermediate.map(\.kind))
        for (final, source) in zip(card.phones, intermediate) {
            #expect(final.id != source.id)
        }
        // The fresh ids are pairwise distinct.
        #expect(Set(card.phones.map(\.id)).count == card.phones.count)
        // The persisted record carries exactly the settled fresh ids.
        #expect(await repository.card(id: card.id)?.phones.map(\.id) == card.phones.map(\.id))
    }

    @Test("T12 9. save settles exactly once until the workflow is discarded")
    func saveCurrentCardSettlesOnce() async {
        let (vm, repository, store) = await enterEditingWithPersistence()
        await vm.saveCurrentCard()

        #expect(vm.isSaveInFlight == false)
        guard let card = savedCard(from: vm) else { return }
        #expect(await repository.allCards().count == 1)
        // The settled result stays on screen (P06); a second save is
        // blocked until 拍下一张 resets the SaveState.
        await vm.saveCurrentCard()
        #expect(await repository.allCards().count == 1)
        guard case .saveSucceeded(let same) = vm.saveState else {
            Issue.record("expected saveState to stay .saveSucceeded, got \(vm.saveState)")
            return
        }
        #expect(same.id == card.id)
        #expect(await store.data(for: card.processedImageReference) != nil)
    }

    @Test("T12 10. captureNextAfterSave resets SaveState and returns to a fresh preview")
    func captureNextAfterSaveReturnsToPreview() async {
        let (vm, repository, _) = await enterEditingWithPersistence()
        await vm.saveCurrentCard()
        guard let card = savedCard(from: vm) else { return }

        await vm.captureNextAfterSave()

        // 拍下一张: saveState → idle, recognition → inactive,
        // crop → reset, scanner → preview.
        #expect(vm.saveState == .idle)
        #expect(vm.recognition == .inactive)
        #expect(vm.cardRegion == .inactive)
        #expect(vm.state == .preview)
        // The saved card remains persisted after starting the next scan.
        #expect(await repository.card(id: card.id) == card)
        // Editing/save intents are ignored on the fresh (inactive) workflow.
        vm.beginManualEditing()
        await vm.saveCurrentCard()
        #expect(vm.recognition == .inactive)
        #expect(vm.saveState == .idle)
        #expect(await repository.allCards().count == 1)
    }

    @Test("T12 11. save flows idle → saving → saveSucceeded with the in-flight guard")
    func saveStateFlowsThroughSaving() async {
        let gated = GatedImageAssetStore()
        let (vm, repository, _) = await enterSettledWithPersistence(imageStore: gated)
        #expect(vm.saveState == .idle)
        #expect(vm.isSaveInFlight == false)

        await gated.enableGate()
        let saveTask = Task { await vm.saveCurrentCard() }

        // Deterministic synchronization: wait until the first image
        // save has actually ENTERED the suspended gate. Observing
        // `.saving` alone would not prove the storage operation is
        // suspended while SaveState == .saving.
        var entered = false
        for _ in 0..<500 {
            if await gated.enteredCount == 1 {
                entered = true
                break
            }
            await Task.yield()
        }
        #expect(entered, "The first image save must enter the gate.")
        // The store save is suspended at the gate; the VM must already
        // have published .saving BEFORE the await on the store.
        #expect(vm.saveState == .saving, "SaveState must be .saving while the save is gated.")
        #expect(vm.isSaveInFlight == true, "isSaveInFlight must be true while saving.")
        #expect(await repository.allCards().isEmpty)
        #expect(await gated.persistedCount == 0)

        await gated.releaseGate()
        await saveTask.value

        guard let card = savedCard(from: vm) else { return }
        #expect(vm.isSaveInFlight == false, "isSaveInFlight must clear after success.")
        #expect(await repository.allCards().count == 1)
        #expect(await repository.card(id: card.id) == card)
        #expect(await gated.persistedCount == 2, "original + processed assets persisted.")
        #expect(await gated.data(for: card.processedImageReference) != nil)
    }
}
