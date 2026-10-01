//
//  DebugCameraFakes.swift
//  SimCamCard
//
//  DEBUG-only deterministic camera dependency injection for UI tests
//  and SwiftUI previews (Week 3 Increment 1).
//
//  Contract (mirrors SimCamCardFixture for card fixtures):
//   - Compiled OUT of Release builds entirely (#if DEBUG).
//   - Normal DEBUG launch without the argument: nil → production real
//     AVFoundation dependencies are used.
//   - `-SimCamCardCamera <mode>` opt-in (DEBUG UI tests only):
//       authorized            → status pre-authorized; fake session
//                               drives S02 preview UI without hardware
//       denied                → pre-denied; permissionDenied UI
//       restricted            → restricted; permissionDenied UI
//       notDeterminedGranted  → undetermined, the (fake) request
//                               resolves granted → preview
//       notDeterminedDenied   → undetermined, the (fake) request
//                               resolves denied → permissionDenied
//
//  This is fixture-driven UI STATE verification only. It is NOT real
//  camera hardware, NOT the native permission dialog and NOT live-frame
//  verification; the fake session is an empty, never-started-by-hardware
//  AVCaptureSession used only to host the preview layer container.
//

#if DEBUG

@preconcurrency import AVFoundation

// MARK: - Fake authorization provider

@MainActor
final class DebugCameraAuthorizationProvider: CameraAuthorizationProviding {

    private var current: CameraAuthorizationStatus
    private let grantOnRequest: Bool

    /// Number of times requestVideoAccess() was invoked — tests assert
    /// that denied/restricted/already-authorized statuses never re-prompt.
    private(set) var requestCount = 0

    init(initialStatus: CameraAuthorizationStatus, grantOnRequest: Bool = false) {
        self.current = initialStatus
        self.grantOnRequest = grantOnRequest
    }

    func videoAuthorizationStatus() -> CameraAuthorizationStatus {
        current
    }

    func requestVideoAccess() async -> Bool {
        requestCount += 1
        // Emulate the native outcome: status changes to the resolved
        // authorization so a subsequent inspection reflects the answer.
        current = grantOnRequest ? .authorized : .denied
        return grantOnRequest
    }
}

// MARK: - Fake session controller

/// Actor fake mirroring the production serialization/idempotency
/// contract (configure once / start many / stop many) without any
/// hardware dependency. Being an actor, its counters and guards are
/// serialized exactly like the real service's serial executor.
actor DebugCameraSessionController: CameraSessionControlling {

    /// An empty session: valid for hosting a preview layer, never
    /// connected to real capture hardware.
    nonisolated let session = AVCaptureSession()

    private(set) var configureCount = 0
    private(set) var startCount = 0
    private(set) var stopCount = 0

    /// When non-nil, `configureIfNeeded()` throws this error to emulate
    /// hardware/configuration failure with permission already granted.
    private let configureError: CameraSessionError?

    init(configureError: CameraSessionError? = nil) {
        self.configureError = configureError
    }

    func configureIfNeeded() async throws {
        guard configureCount == 0 else { return } // configure-once
        configureCount += 1
        if let configureError {
            throw configureError
        }
    }

    func start() async throws {
        startCount += 1
        // Deliberately does NOT call session.startRunning(): no hardware
        // dependency, no simulator audio/camera side effects. Never
        // throws in UI fixtures (start-failure injection is covered by
        // the unit-test fake).
    }

    func stop() async {
        stopCount += 1
    }
}

// MARK: - Launch-argument environment

enum DebugCameraEnvironment {

    static let launchArgument = "-SimCamCardCamera"

    enum Mode: String {
        case authorized
        case denied
        case restricted
        case notDeterminedGranted = "notdeterminedgranted"
        case notDeterminedDenied = "notdetermineddenied"
    }

    /// Returns a fixture-configured ScanViewModel when the launch
    /// requests one; nil for normal launches (real AVFoundation path).
    static func makeViewModelIfRequested(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> ScanViewModel? {
        guard let index = arguments.firstIndex(of: launchArgument),
              index + 1 < arguments.count,
              let mode = Mode(rawValue: arguments[index + 1].lowercased())
        else {
            return nil
        }

        let authorization: DebugCameraAuthorizationProvider
        switch mode {
        case .authorized:
            authorization = DebugCameraAuthorizationProvider(initialStatus: .authorized)
        case .denied:
            authorization = DebugCameraAuthorizationProvider(initialStatus: .denied)
        case .restricted:
            authorization = DebugCameraAuthorizationProvider(initialStatus: .restricted)
        case .notDeterminedGranted:
            authorization = DebugCameraAuthorizationProvider(
                initialStatus: .notDetermined, grantOnRequest: true
            )
        case .notDeterminedDenied:
            authorization = DebugCameraAuthorizationProvider(
                initialStatus: .notDetermined, grantOnRequest: false
            )
        }

        return ScanViewModel(
            authorization: authorization,
            sessionController: DebugCameraSessionController()
        )
    }
}

extension ScanViewModel {

    /// DEBUG launch composition: fixture VM when requested, otherwise
    /// the production real-AVFoundation VM. Release builds call the
    /// real initializer directly (this extension does not exist there).
    static func configuredForDebugLaunch() -> ScanViewModel {
        DebugCameraEnvironment.makeViewModelIfRequested() ?? ScanViewModel()
    }
}

#endif
