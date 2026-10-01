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
        private let configureError: CameraSessionError?
        private let startError: CameraSessionError?

        init(
            configureError: CameraSessionError? = nil,
            startError: CameraSessionError? = nil
        ) {
            self.configureError = configureError
            self.startError = startError
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
}
