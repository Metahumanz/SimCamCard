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
        vm.handleSelectedImage(importedBytes)

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
        vm.handleSelectedImage(Data([0x01, 0x02]))

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
        vm.handleSelectedImage(Data([0x01, 0x02]))

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
        vm.handleSelectedImage(bytes)
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
}
