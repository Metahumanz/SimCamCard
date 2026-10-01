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
/// DEBUG-only P04 crop fixture mode: drives the still pipeline into a
/// deterministic crop page without real camera/picker interaction.
enum CropFixtureMode: String {
    /// Crop page enters with the automatic (detected) region.
    case auto
    /// Crop page enters directly in manual-adjusting state.
    case manual
    /// Crop page prepares and immediately confirms.
    case confirmed
}
typealias CropFixtureParam = CropFixtureMode?
#else
/// In Release no photo-import fixture exists; the parameter type is an
/// always-nil placeholder so the same init signature compiles.
typealias PhotoImportFixtureParam = Never?
typealias CropFixtureParam = Never?
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

    /// T06 live card-detection state (Week 3 Increment 4). Deliberately
    /// a SEPARATE state family from the S02 camera `State`: `.preview`
    /// continues to mean "camera session running" and must NOT also
    /// carry the mutually-exclusive detection overlay. Maps frozen S02
    /// `cardNotDetected` / `cardDetected` without changing the camera
    /// state machine.
    enum CardDetectionState: Equatable {
        /// Detection is not running: not in preview, or a
        /// capture/import/leave-scanner transition has explicitly
        /// ended it. No overlay is rendered.
        case inactive
        /// Preview is running but Vision currently reports no card.
        case cardNotDetected
        /// Preview is running and Vision reports a card quadrilateral.
        case cardDetected(CardRegion)
    }

    /// Current T06 detection state. `.inactive` unless the camera is
    /// in `.preview`.
    private(set) var cardDetection: CardDetectionState = .inactive

    // MARK: - S04 Card Region (P04 Crop / Boundary Adjust)

    /// Separate S04 state family (Week 3 Increment 5). Deliberately
    /// NOT merged into the camera `State`: S04 begins AFTER a capture
    /// or import already produced a still image, and retake returns to
    /// the scanner. Frozen S04 mapping:
    ///   autoDetected   ↔ `.autoDetected(CropDraft)`
    ///   manualAdjusting↔ `.manualAdjusting(CropDraft)`
    ///   confirmed      ↔ `.confirmed(CardCropResult)`
    ///   retakeRequested↔ `.retakeRequested`
    /// `.preparing` / `.failed` are implementation transients, not
    /// frozen S04 states.
    enum CardRegionState: Equatable {
        /// No crop workflow active (Scanner visible).
        case inactive
        /// Still decode + detection running (implementation transient).
        case preparing
        /// S04 autoDetected: Vision found the initial region; no
        /// accepted manual edit yet.
        case autoDetected(CropDraft)
        /// S04 manualAdjusting: no-detection fallback OR at least one
        /// accepted manual corner edit.
        case manualAdjusting(CropDraft)
        /// S04 confirmed: perspective-corrected result produced.
        case confirmed(CardCropResult)
        /// S04 retakeRequested: the draft/result is discarded and the
        /// Scanner is being restored (transient).
        case retakeRequested
        /// Preparation/correction failed (implementation transient).
        case failed(CropError)

        var draft: CropDraft? {
            switch self {
            case .autoDetected(let draft), .manualAdjusting(let draft):
                return draft
            case .inactive, .preparing, .confirmed, .retakeRequested, .failed:
                return nil
            }
        }

        /// True while P04 must own the screen content.
        var isCropScreenActive: Bool {
            switch self {
            case .inactive, .retakeRequested: return false
            case .preparing, .autoDetected, .manualAdjusting, .confirmed, .failed:
                return true
            }
        }
    }

    /// Current S04 state. `.inactive` until a capture/import enters the
    /// still pipeline.
    private(set) var cardRegion: CardRegionState = .inactive

    /// Transient confirm-in-flight guard (NOT a frozen state): while
    /// true 完成 is disabled and a second tap cannot start a second
    /// Core Image correction.
    private(set) var isCropInFlight = false

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

    /// P04 crop fixture mode (DEBUG only; `Never?` in Release).
    private let cropFixture: CropFixtureParam

    /// Heavy still pipeline (decode / Vision / Core Image) runs on this
    /// service's dedicated serial executor — never synchronously on the
    /// MainActor.
    private let cropProcessor: any CardCropProcessing

    /// The single Task consuming the live detection stream while in
    /// `.preview`. Cancelled on scanner disappear, on capture, on photo
    /// import, and on any transition out of preview. Never more than
    /// one consumer exists at a time; never a Task.detached.
    private var detectionConsumer: Task<Void, Never>?

    init(
        authorization: CameraAuthorizationProviding = AVCameraAuthorizationProvider(),
        sessionController: (any CameraSessionControlling)? = nil,
        photoImportFixture: PhotoImportFixtureParam = nil,
        cropProcessor: (any CardCropProcessing)? = nil,
        cropFixture: CropFixtureParam = nil
    ) {
        self.authorization = authorization
        let controller = sessionController ?? CameraSessionController()
        self.sessionController = controller
        self.cameraSession = controller.session
        self.photoImportFixture = photoImportFixture
        self.cropProcessor = cropProcessor ?? CardCropProcessor()
        self.cropFixture = cropFixture
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
        stopDetectionConsumption()
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
            stopDetectionConsumption()
            state = .captured(photo)
            // Shared still pipeline: camera capture enters P04 exactly
            // like a photo-library import.
            await prepareCrop(photo)
        } catch let error as CameraSessionError {
            // Failure path must also release the camera session: never
            // leave the session running behind the error fallback.
            await sessionController.stop()
            stopDetectionConsumption()
            state = .cameraUnavailable(error)
        } catch {
            await sessionController.stop()
            stopDetectionConsumption()
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

        // Live detection ends while the import flow owns the scanner
        // content; the camera is released before presenting the system
        // picker.
        stopDetectionConsumption()
        await sessionController.stop()

        #if DEBUG
        if let fixture = photoImportFixture {
            switch fixture {
            case .imported:
                await handleSelectedImage(DebugCameraSessionController.fixtureImageData)
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
    /// truth; `PhotosPickerItem` is never stored. The image enters the
    /// SAME shared still pipeline as a camera capture (prepare → P04).
    func handleSelectedImage(_ data: Data) async {
        isPickerPresented = false
        let photo = CapturedPhoto(data: data, source: .photoLibrary)
        photoImport = .imageSelected(photo)
        await prepareCrop(photo)
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
            startDetectionConsumption()
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
            startDetectionConsumption()
        } catch let error as CameraSessionError {
            state = .cameraUnavailable(error)
        } catch {
            state = .cameraUnavailable(.cannotAddVideoInput)
        }
    }

    // MARK: - Live detection consumption (T06)

    /// Starts consuming the detection stream for the current preview
    /// lifecycle. The initial state is `cardNotDetected`; every
    /// delivered region flips it to `cardDetected`, every nil flips it
    /// back. At most one consumer exists at a time; the task is
    /// cancelled by `stopDetectionConsumption()` whenever the scanner
    /// leaves a state that renders the live feed.
    private func startDetectionConsumption() {
        stopDetectionConsumption()
        cardDetection = .cardNotDetected
        detectionConsumer = Task { [weak self] in
            guard let stream = await self?.sessionController.makeDetectionEvents() else { return }
            for await region in stream {
                guard !Task.isCancelled else { break }
                guard let self, self.state == .preview, self.photoImport == .idle else { continue }
                self.cardDetection = region.map(CardDetectionState.cardDetected) ?? .cardNotDetected
            }
        }
    }

    /// Ends live detection and clears the overlay state. Called on
    /// scanner disappear, capture, photo import, and any transition
    /// out of preview. Safe to call repeatedly.
    private func stopDetectionConsumption() {
        detectionConsumer?.cancel()
        detectionConsumer = nil
        cardDetection = .inactive
    }

    // MARK: - S04 Crop workflow (P04)

    /// Runs the shared still pipeline: decode → orientation resolve →
    /// still rectangle detection → initial CropDraft. Heavy work happens
    /// on the crop processor's dedicated serial executor.
    ///
    /// Detection success → `.autoDetected` (S04); no-detection fallback
    /// → `.manualAdjusting` (implementation robustness); undecodable
    /// data → `.failed(.invalidImageData)` (stable, no crash).
    private func prepareCrop(_ photo: CapturedPhoto) async {
        cardRegion = .preparing
        do {
            let preparation = try await cropProcessor.prepare(photo)

            #if DEBUG
            switch cropFixture {
            case .manual:
                cardRegion = .manualAdjusting(preparation.draft)
            case .confirmed:
                cardRegion = preparation.wasDetected
                    ? .autoDetected(preparation.draft)
                    : .manualAdjusting(preparation.draft)
                await performCropConfirmation()
            case .auto, nil:
                cardRegion = preparation.wasDetected
                    ? .autoDetected(preparation.draft)
                    : .manualAdjusting(preparation.draft)
            }
            #else
            cardRegion = preparation.wasDetected
                ? .autoDetected(preparation.draft)
                : .manualAdjusting(preparation.draft)
            #endif
        } catch let error as CropError {
            cardRegion = .failed(error)
        } catch {
            cardRegion = .failed(.invalidImageData)
        }
    }

    /// User dragged one corner. The candidate is applied ONLY when it
    /// still forms a valid convex quadrilateral — an invalid move is
    /// ignored, so the draft can never become a bow-tie/collapsed
    /// region. The first accepted edit transitions autoDetected →
    /// manualAdjusting; later edits stay there.
    func moveCorner(_ corner: CardCorner, to point: NormalizedPoint) {
        // Confirmation in-flight freeze (pre-Accept correction): the
        // draft is immutable while a correction is running, so a stale
        // correction result can never clobber a concurrent drag.
        guard !isCropInFlight, let draft = cardRegion.draft else { return }
        let candidate = draft.moving(corner, to: point)
        guard CardRegionGeometry.isValid(candidate.region) else { return }
        cardRegion = .manualAdjusting(candidate)
    }

    /// User tapped 完成: perspective-correct the current valid region
    /// exactly once. Guarded by `isCropInFlight` so a double tap cannot
    /// start two Core Image corrections. On failure the draft stays
    /// usable (`.failed` surfaces the stable fallback).
    func confirmCrop() async {
        guard !isCropInFlight, let draft = cardRegion.draft else { return }
        isCropInFlight = true
        defer { isCropInFlight = false }
        await performCropConfirmation(draft: draft)
    }

    private func performCropConfirmation(draft providedDraft: CropDraft? = nil) async {
        guard let draft = providedDraft ?? cardRegion.draft else { return }
        do {
            let result = try await cropProcessor.perspectiveCorrect(draft)
            cardRegion = .confirmed(result)
        } catch let error as CropError {
            cardRegion = .failed(error)
        } catch {
            cardRegion = .failed(.correctionFailed)
        }
    }

    /// User tapped 取消 (P04 retake): discard the draft/result, clear
    /// the captured/imported transitional state, restart the camera
    /// preview and resume live detection. For a photo-library source
    /// this returns to the same Scanner (no system picker is re-opened).
    /// A restart failure maps to `cameraUnavailable` — the existing
    /// camera failure contract is preserved.
    func retake() async {
        // In-flight freeze: a correction that is already running must
        // settle before retake can reset the workflow — otherwise
        // "confirm → retake to scanner → old confirm returns" would
        // resurrect a stale .confirmed state.
        guard cardRegion.isCropScreenActive, !isCropInFlight else { return }
        cardRegion = .retakeRequested

        // Clear still-image transitional state before restarting.
        photoImport = .idle
        isPickerPresented = false
        isCropInFlight = false

        // configureIfNeeded() already succeeded on first scanner entry;
        // restartPreview() runs idempotent start() and flips the camera
        // state back to .preview (or .cameraUnavailable on failure).
        await restartPreview()
        cardRegion = .inactive
    }
}
