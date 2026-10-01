//
//  CameraSessionController.swift
//  SimCamCard
//
//  Camera session service for the Scanner (Week 3 Increment 1,
//  concurrency-corrected).
//
//  Scope:
//   - One AVCaptureSession with a single rear video input feeding the
//     live preview layer, plus ONE AVCapturePhotoOutput for T04
//     single-card still capture (added exactly once, minimal settings).
//   - Idempotent lifecycle: configure once; start many; stop many.
//   - Single in-flight capture: a second capturePhoto() request while
//     one is in flight throws `captureFailed`.
//   - NOT configured: metadata output, Vision/OCR, rectangle detection,
//     QR, audio. No microphone permission is ever requested. No flash
//     UI, burst, bracket, RAW, Live Photo, depth or portrait effects.
//
//  Concurrency ownership (Swift 6, correction supersedes the original
//  MainActor-owned design):
//   - Apple guidance: AVCaptureSession configuration is expensive and
//     startRunning()/stopRunning() are BLOCKING calls; the camera
//     session lifecycle must NOT run on the main thread.
//   - This type is therefore an `actor` whose work executes on a
//     dedicated serial executor (`DispatchSerialQueue` exposed via
//     `unownedExecutor`). All of:
//         beginConfiguration / commitConfiguration / input mutation /
//         startRunning / stopRunning
//     run strictly serialized on that one non-main serial context.
//   - The AVCaptureSession is owned by this actor and never crosses to
//     another isolation domain for mutation; it is exposed read-only
//     (`nonisolated let`) for the preview layer only. The current SDK
//     exposes AVCaptureSession as non-Sendable for this Swift 6 build,
//     so `@preconcurrency import AVFoundation` is used as a narrow
//     compatibility/interoperability bridge for the display-only
//     preview-session reference. NOTE: @preconcurrency only relaxes
//     COMPILE-TIME diagnostics — it does not itself guarantee thread
//     safety. Safety here relies on the explicit ownership contract:
//     all session mutation/configure/start/stop occurs on this actor's
//     dedicated serial executor; MainActor/UI only attaches the
//     session to AVCaptureVideoPreviewLayer for presentation and never
//     mutates session topology or lifecycle.
//     NOT `@unchecked Sendable`, NOT `nonisolated(unsafe)`, NOT
//     `Task.detached`.
//   - UI-facing state remains MainActor-owned by ScanViewModel, which
//     awaits this actor's async API.
//
//  Ordering contract:
//   - configureIfNeeded(): runs the expensive configuration at most
//     once; later calls are no-ops. A failed configure does NOT mark
//     the session configured (a later call may retry).
//   - start()/stop(): serialized with configuration; start is a no-op
//     until configuration has succeeded; both are idempotent via the
//     session's running flag.
//

@preconcurrency import AVFoundation
import Dispatch

/// Hardware/configuration failure while preparing the camera.
///
/// This is an INFRASTRUCTURE error, distinct from S02
/// `permissionDenied`: a user may grant permission and still have no
/// usable camera (e.g. simulator, no rear device, input conflict).
enum CameraSessionError: Error, Equatable {
    /// No rear video device is available on this hardware.
    case noVideoDevice
    /// The video input could not be added to the session.
    case cannotAddVideoInput
    /// `startRunning()` returned but the session did not actually
    /// start (runtime start failure). AVFoundation does NOT report
    /// this via Swift throw; it is detected by the post-start
    /// `isRunning` contract check on the serial executor.
    case startFailed
    /// The photo output could not be added to the session (T04).
    case cannotAddPhotoOutput
    /// The capture request failed (delegate reported an error), or a
    /// capture was requested while the session was not running.
    case captureFailed
    /// The capture delegate delivered no usable image bytes.
    case emptyPhotoData
}

/// Camera session lifecycle service. Implementations execute ALL
/// AVCaptureSession work on one dedicated non-main serial context;
/// every entry point is async so callers (MainActor UI code) never
/// block the main thread on AVFoundation.
///
/// Explicitly `nonisolated`: the project sets
/// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor, which would otherwise
/// make this protocol MainActor-isolated and prevent actor
/// conformance. `nonisolated` keeps the conformance open to the
/// serial-executor actor implementation.
nonisolated protocol CameraSessionControlling: Sendable {

    /// The live capture session rendered by the preview layer.
    /// Read-only exposure for presentation; lifecycle ownership stays
    /// with the service. Non-isolated because the reference is
    /// display-only (bridged by `@preconcurrency import AVFoundation`,
    /// which relaxes compile-time checks only — safety comes from the
    /// ownership contract, not the annotation).
    nonisolated var session: AVCaptureSession { get }

    /// Configures the session exactly once; repeated calls after a
    /// success are no-ops. Throws CameraSessionError on hardware or
    /// configuration failure. Serialized with start/stop.
    func configureIfNeeded() async throws

    /// Starts the running session (idempotent; no-op if configuration
    /// has not succeeded or the session is already running).
    ///
    /// `startRunning()` is blocking and does NOT throw on failure, so
    /// this verifies the result contract: after the blocking call
    /// returns, `session.isRunning` must be true. Throws
    /// `CameraSessionError.startFailed` otherwise — a failed start
    /// must never surface to the UI as a preview state.
    func start() async throws

    /// Stops the running session (idempotent; safe when not running).
    func stop() async

    /// Captures one still photo (T04 single-card workflow).
    ///
    /// Requires a configured, running session (i.e. the caller must be
    /// in the S02 preview state). At most ONE capture may be in flight
    /// at a time; implementations reject or serialize additional
    /// requests. Throws `CameraSessionError.captureFailed` /
    /// `.emptyPhotoData` on failure — a failed capture must never
    /// produce a CapturedPhoto.
    func capturePhoto() async throws -> CapturedPhoto
}

actor CameraSessionController: CameraSessionControlling {

    /// Dedicated serial queue backing this actor's executor. All
    /// blocking AVFoundation work (configure/start/stop) is guaranteed
    /// to run here — never on the main thread, never concurrently.
    /// `nonisolated`: read by `unownedExecutor` (a nonisolated
    /// requirement); the queue reference itself is immutable.
    nonisolated let sessionQueue = DispatchSerialQueue(
        label: "com.metahumanz.SimCamCard.camera.session"
    )

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }

    /// Owned by this actor for its whole lifetime. `nonisolated let`
    /// exposes it read-only for the preview layer (display only);
    /// every mutation stays on this actor's serial executor. The
    /// cross-isolation reference is bridged by `@preconcurrency
    /// import AVFoundation` above — no unsafe Sendable anywhere.
    ///
    /// Created inline: instantiating an empty AVCaptureSession is
    /// cheap (Apple's blocking-call guidance targets configuration
    /// and start/stop, which all run on `sessionQueue`).
    nonisolated let session = AVCaptureSession()

    /// The still-capture output. Added to the session exactly once in
    /// `configureIfNeeded()`; minimal single-photo configuration only
    /// (no flash UI, burst, bracket, RAW, Live Photo, depth, portrait
    /// effects or metadata output).
    private let photoOutput = AVCapturePhotoOutput()

    /// Strongly-held delegate bridge for the at-most-one in-flight
    /// capture. Non-nil while a capture is in flight; guarantees the
    /// delegate outlives the AVFoundation callback. Cleared when the
    /// continuation resumes.
    private var inFlightCapture: PhotoCaptureProcessor?

    private var isConfigured = false

    func configureIfNeeded() async throws {
        // Configure once. Re-entering the Scanner reuses the same
        // configured session + input (no duplicate inputs). A failure
        // leaves isConfigured false so a later entry may retry.
        guard !isConfigured else { return }

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraSessionError.noVideoDevice
        }

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            throw CameraSessionError.noVideoDevice
        }

        session.beginConfiguration()
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw CameraSessionError.cannotAddVideoInput
        }
        session.addInput(input)

        // T04: one photo output, added exactly once, inside the same
        // configuration transaction. canAddOutput failure is an
        // infrastructure error — never disguised as permissionDenied.
        guard session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            throw CameraSessionError.cannotAddPhotoOutput
        }
        session.addOutput(photoOutput)

        session.commitConfiguration()

        isConfigured = true
    }

    func start() async throws {
        guard isConfigured, !session.isRunning else { return }
        session.startRunning()
        // startRunning() blocks until the session has started or failed
        // to start, and does not throw. Verify the result: if the
        // session is not running after the blocking call returned, the
        // start failed — report it instead of letting the UI enter
        // preview. (AVCaptureSessionRuntimeErrorNotification observation
        // for mid-stream runtime errors, interruption handling and
        // recovery are deferred robustness, out of this increment.)
        guard session.isRunning else {
            throw CameraSessionError.startFailed
        }
    }

    func stop() async {
        guard isConfigured, session.isRunning else { return }
        session.stopRunning()
    }

    func capturePhoto() async throws -> CapturedPhoto {
        // Single-card contract: reject when not capturing-capable or
        // when a capture is already in flight. The actor's serial
        // executor makes this check-and-set atomic.
        guard isConfigured, session.isRunning else {
            throw CameraSessionError.captureFailed
        }
        guard inFlightCapture == nil else {
            throw CameraSessionError.captureFailed
        }

        // Minimal single-photo settings: SDK defaults (HEIF/JPEG per
        // device support). No flash UI, burst, bracket, RAW, Live
        // Photo, depth or portrait effects.
        let settings = AVCapturePhotoSettings()

        // The processor is strongly held in `inFlightCapture` for the
        // entire capture so the AVFoundation delegate callback always
        // has a live target; cleared on both success and failure paths.
        defer { inFlightCapture = nil }
        return try await withCheckedThrowingContinuation { continuation in
            let processor = PhotoCaptureProcessor(continuation: continuation)
            inFlightCapture = processor
            photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }
}
