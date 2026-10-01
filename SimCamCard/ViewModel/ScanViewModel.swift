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
//  Only states used by THIS increment exist. Increment 2 adds the
//  frozen S02 `captured` state. `cardDetected`, `recognizing`,
//  `cropping` remain intentionally absent and must be added by the
//  increments that introduce them.
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

#if DEBUG
/// DEBUG-only fixture mode for deterministic photo-import UI
/// regression. When non-nil, `beginPhotoImport()` simulates the picker
/// result directly (bypassing the real system `PhotosPicker`) so UI
/// tests do not drive native picker UI. Compiled out of Release.
enum PhotoImportFixtureMode: String {
    /// Simulate a successful selection with valid fixture image bytes.
    case imported
    /// Simulate the user cancelling the picker.
    case cancel
    /// Simulate a successful selection whose image data fails to load.
    case loadFailure = "loadfailure"
}
/// In DEBUG the photo-import fixture parameter carries a real mode.
typealias PhotoImportFixtureParam = PhotoImportFixtureMode?
#else
/// In Release no photo-import fixture exists; the parameter type is an
/// always-nil placeholder so the same init signature compiles.
typealias PhotoImportFixtureParam = Never?
#endif

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
        /// S02 captured (T04): a still photo was taken successfully.
        /// The session has been stopped; the raw photo bytes travel
        /// with the state for the (later) Detection/Crop/OCR pipeline.
        /// No navigation, BusinessCard creation or Repository save.
        case captured(CapturedPhoto)
        /// Permission granted but camera hardware/configuration/capture
        /// failed. NOT an S02 permission state — an infrastructure
        /// fallback. Capture failures map here as the minimal stable
        /// infrastructure fallback (no retry UI in this increment).
        case cameraUnavailable(CameraSessionError)
    }

    /// S03 photo-import transient state (Week 3 Increment 3 — T05
    /// mechanics). Deliberately a SEPARATE state family from S02
    /// `State`: the camera state machine and the picker presentation
    /// state must not be merged into one mutually-exclusive enum. The
    /// View renders `photoImport` with priority over `state` (a
    /// selected/imported image shows on top of the underlying camera
    /// state).
    enum PhotoImportState: Equatable {
        /// No import in progress. This is a TERMINAL marker: it is set
        /// only after the import lifecycle has fully ended (selection
        /// handled, load failure recorded, or — on cancel — the camera
        /// restart resolved). It never means "camera still restarting".
        case idle
        /// The system `PhotosPicker` is (or should be) presented.
        case pickerPresented
        /// The user selected an image and its bytes loaded
        /// successfully. The camera session stays stopped.
        case imageSelected(CapturedPhoto)
        /// A selection was made but the image data could not be loaded.
        /// Distinct from `cameraUnavailable` — this is a photo-import
        /// failure, not a camera-infrastructure failure.
        case importFailed
    }

    private(set) var state: State = .permissionUnknown

    /// S03 photo-import transient state. Defaults to `.idle`.
    private(set) var photoImport: PhotoImportState = .idle

    /// Whether the system `PhotosPicker` sheet should be presented.
    /// Driven by `beginPhotoImport()`; cleared by every terminal
    /// import outcome (selected / cancelled / load failure).
    private(set) var isPickerPresented = false

    /// Transient capture-in-flight guard (NOT a frozen S02 state).
    /// While true the shutter is disabled and a second tap cannot
    /// start a second capture workflow (single-card contract).
    private(set) var isCaptureInFlight = false

    /// The capture session the preview layer renders. Owned by the
    /// CameraSessionController actor (which alone mutates it); exposed
    /// here read-only so CameraPreviewView can display it. Available
    /// immediately; only running in `.preview`.
    let cameraSession: AVCaptureSession

    private let authorization: CameraAuthorizationProviding
    private let sessionController: any CameraSessionControlling
    /// Photo-import fixture mode. In DEBUG this is
    /// `PhotoImportFixtureMode?` (drives deterministic import UI
    /// regression); in Release it is `Never?` (always nil, fixture
    /// path compiled out).
    private let photoImportFixture: PhotoImportFixtureParam

    init(
        authorization: CameraAuthorizationProviding = AVCameraAuthorizationProvider(),
        sessionController: (any CameraSessionControlling)? = nil,
        photoImportFixture: PhotoImportFixtureParam = nil
    ) {
        self.authorization = authorization
        let controller = sessionController ?? CameraSessionController()
        self.sessionController = controller
        self.cameraSession = controller.session
        self.photoImportFixture = photoImportFixture
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

    // MARK: - Capture (T04 still capture)

    /// Shutter action. Only accepted in a REAL scanner-ready state:
    /// `state == .preview` AND no photo-import flow active AND the
    /// system picker not presented. `.preview` can remain set while
    /// the camera session is stopped behind the import picker, so the
    /// camera state alone is NOT sufficient — camera-only actions must
    /// also be gated on the photo-import lifecycle. Ignored in every
    /// other state (permissionUnknown / permissionDenied /
    /// cameraUnavailable / captured / any active import state) and
    /// while a capture is already in flight — the single-card contract
    /// allows at most one capture workflow at a time. Never rely on the
    /// system picker sheet visually covering the shutter for business
    /// correctness.
    ///
    /// Success lifecycle: capture → obtain CapturedPhoto → STOP the
    /// session (release the camera; deterministic input for the later
    /// pipeline) → state = .captured(photo).
    ///
    /// Failure lifecycle: STOP the session (the camera must not stay
    /// running behind the error fallback), no crash, never .captured,
    /// never disguised as permissionDenied — mapped to the stable
    /// infrastructure fallback `.cameraUnavailable(...)`.
    func capture() async {
        guard state == .preview,
              photoImport == .idle,
              !isPickerPresented,
              !isCaptureInFlight else { return }
        isCaptureInFlight = true
        defer { isCaptureInFlight = false }

        do {
            let photo = try await sessionController.capturePhoto()
            await sessionController.stop()
            state = .captured(photo)
        } catch let error as CameraSessionError {
            // Failure path must also release the camera session: never
            // leave the session running behind the error fallback.
            await sessionController.stop()
            state = .cameraUnavailable(error)
        } catch {
            await sessionController.stop()
            state = .cameraUnavailable(.captureFailed)
        }
    }

    // MARK: - Photo Import (T05 mechanics — S03)

    /// User tapped 相册. Only accepted in `.preview` with no import
    /// already in flight — prevents presenting two pickers at once.
    ///
    /// Lifecycle (§11): stop the camera session (don't hold the camera
    /// behind the picker), then present the system `PhotosPicker`. In
    /// DEBUG fixture mode the picker result is simulated directly
    /// (bypassing native picker UI for deterministic UI regression).
    func beginPhotoImport() async {
        guard state == .preview, !isPickerPresented, photoImport == .idle else { return }

        // Release the camera before presenting the system picker.
        await sessionController.stop()

        #if DEBUG
        if let fixture = photoImportFixture {
            switch fixture {
            case .imported:
                handleSelectedImage(DebugCameraSessionController.fixtureImageData)
            case .cancel:
                await handleImportCancel()
            case .loadFailure:
                handleImportLoadFailure()
            }
            return
        }
        #endif

        isPickerPresented = true
        photoImport = .pickerPresented
    }

    /// The system picker dismissed AFTER the user made a selection
    /// (presentation-only transition). This is NOT a cancel: it ONLY
    /// clears the presentation flag so the dismissed sheet cannot be
    /// re-presented by a stale binding. It does NOT restart the camera,
    /// does NOT set `photoImport = .idle`, does NOT mark selection
    /// success and does NOT load any image.
    ///
    /// Transient loading contract: after this call and until
    /// `handleSelectedImage` / `handleImportLoadFailure` runs,
    ///   isPickerPresented == false
    ///   photoImport == .pickerPresented   (selection still resolving)
    ///   camera remains stopped
    func photoPickerDidDismissAfterSelection() {
        isPickerPresented = false
    }

    /// The system picker returned a selected image and its bytes loaded
    /// successfully. The camera session stays stopped (we do NOT
    /// restart it after a selection — §11). `data` is the source of
    /// truth; `PhotosPickerItem` is never stored.
    func handleSelectedImage(_ data: Data) {
        isPickerPresented = false
        photoImport = .imageSelected(
            CapturedPhoto(data: data, source: .photoLibrary)
        )
    }

    /// The user cancelled the system picker (first-class behavior,
    /// §12): no crash, no fake image, no `imageSelected`.
    ///
    /// Ordering contract: dismiss the picker flag → restart the camera
    /// → ONLY THEN leave the picker flow (`photoImport = .idle`).
    /// `photoImport == .idle` is a terminal marker meaning the import
    /// lifecycle has FULLY ended; it must never be observed while the
    /// camera is still restarting. If the restart fails, `state`
    /// becomes `.cameraUnavailable` (never `.preview`) and the picker
    /// flow still ends cleanly in `.idle` — the import itself is over;
    /// the camera failure is surfaced through the camera state.
    func handleImportCancel() async {
        isPickerPresented = false
        await restartPreview()
        photoImport = .idle
    }

    /// A picker selection succeeded but loading the image data failed
    /// (§14). Never crash, never fabricate an image, never silently
    /// return to preview as if nothing happened. Mapped to the
    /// photo-import-specific `.importFailed` state — NOT to
    /// `cameraUnavailable` (different failure domain).
    func handleImportLoadFailure() {
        isPickerPresented = false
        photoImport = .importFailed
    }

    // MARK: - Session orchestration

    private func beginPreview() async {
        // Starting the session is a camera-only intent: never start
        // while a photo-import flow owns the scanner content (e.g. an
        // imported image is showing and the camera must stay stopped).
        guard photoImport == .idle, !isPickerPresented else { return }
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

    /// Restart the preview after a photo-import cancel. Configuration
    /// was already done during the first entry, so only `start()` is
    /// needed here (idempotent via the service's running flag). A
    /// start failure maps to `cameraUnavailable`, never `.preview`.
    private func restartPreview() async {
        do {
            try await sessionController.start()
            state = .preview
        } catch let error as CameraSessionError {
            state = .cameraUnavailable(error)
        } catch {
            state = .cameraUnavailable(.cannotAddVideoInput)
        }
    }
}
