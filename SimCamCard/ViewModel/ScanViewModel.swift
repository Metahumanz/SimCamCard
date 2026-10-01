//
//  ScanViewModel.swift
//  SimCamCard
//
//  UI-facing scanner state owner (Week 3 Increment 1).
//
//  Week 2 correctly had no ScanViewModel — the static shell carried no
//  real state. Week 3 introduces real camera permission/preview state,
//  so this ViewModel now owns the S02 state machine for this increment:
//
//    permissionUnknown ──grant──▶ preview
//             │
//             └──deny──────────▶ permissionDenied
//    denied / restricted ───────▶ permissionDenied (no re-prompt)
//    authorized ────────────────▶ preview (no prompt)
//
//  Only states used by THIS increment exist. `cardDetected`,
//  `captured`, `recognizing`, `cropping` are intentionally absent and
//  must be added by the increments that introduce them.
//
//  Infrastructure failures (no camera hardware, input configuration
//  failure) are a separate `cameraUnavailable` state — never disguised
//  as `permissionDenied`: permission can be granted while the device
//  still cannot produce a preview (e.g. iOS Simulator).
//
//  Spec sources:
//   - spec/state-inventory.md S02 permissionUnknown / permissionDenied
//     / preview
//   - spec/reference-tests.md T03 Camera Permission
//

@preconcurrency import AVFoundation

@MainActor
@Observable
final class ScanViewModel {

    /// S02 states implemented in this increment (+ infrastructure
    /// fallback). Equatable so unit tests can assert exact transitions.
    enum State: Equatable {
        /// Permission has not been resolved yet; waiting on the native
        /// permission result. The Scanner shows its normal shell while
        /// the system dialog is presented.
        case permissionUnknown
        /// User denied, or access is restricted. No session is started.
        case permissionDenied
        /// Permission granted and the live preview session is running.
        case preview
        /// Permission granted but camera hardware/configuration failed.
        /// NOT an S02 permission state — an infrastructure fallback.
        case cameraUnavailable(CameraSessionError)
    }

    private(set) var state: State = .permissionUnknown

    /// The capture session the preview layer renders. Owned by the
    /// CameraSessionController actor (which alone mutates it); exposed
    /// here read-only so CameraPreviewView can display it. Available
    /// immediately; only running in `.preview`.
    let cameraSession: AVCaptureSession

    private let authorization: CameraAuthorizationProviding
    private let sessionController: any CameraSessionControlling

    init(
        authorization: CameraAuthorizationProviding = AVCameraAuthorizationProvider(),
        sessionController: (any CameraSessionControlling)? = nil
    ) {
        self.authorization = authorization
        let controller = sessionController ?? CameraSessionController()
        self.sessionController = controller
        self.cameraSession = controller.session
    }

    // MARK: - Lifecycle

    /// Called when the Scanner appears. Inspects authorization, prompts
    /// exactly once via the native dialog when undetermined, and starts
    /// the preview session when access is granted.
    ///
    /// Session work (configure/start) is awaited on the session
    /// service's dedicated serial executor — the MainActor is never
    /// blocked by AVFoundation calls.
    ///
    /// Re-entering the Scanner after a Back is safe: an already
    /// authorized status never prompts again; `configureIfNeeded()` is
    /// a no-op after the first success and `start()` restarts the
    /// stopped session without creating duplicate inputs.
    func scannerDidAppear() async {
        switch authorization.videoAuthorizationStatus() {
        case .notDetermined:
            state = .permissionUnknown
            let granted = await authorization.requestVideoAccess()
            if granted {
                await beginPreview()
            } else {
                state = .permissionDenied
            }
        case .authorized:
            // Already granted — do NOT request again.
            await beginPreview()
        case .denied, .restricted:
            // Never re-prompt a denied/restricted user; never start a
            // session they cannot use.
            state = .permissionDenied
        }
    }

    /// Called when the Scanner disappears (Back/close). Stops the
    /// session so the camera is released; configuration is retained for
    /// cheap re-entry. Async because stop is dispatched to the session
    /// service's serial executor.
    func scannerDidDisappear() async {
        await sessionController.stop()
    }

    // MARK: - Session orchestration

    private func beginPreview() async {
        do {
            try await sessionController.configureIfNeeded()
            // start() throws when the session fails to actually start
            // (post-blocking-call isRunning contract) — a start failure
            // must NEVER surface as preview.
            try await sessionController.start()
            state = .preview
        } catch let error as CameraSessionError {
            state = .cameraUnavailable(error)
        } catch {
            // No other failure mode is known; keep the state honest
            // rather than crashing or silently staying on the shell.
            state = .cameraUnavailable(.cannotAddVideoInput)
        }
    }
}
