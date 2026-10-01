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
//     single-card still capture (added exactly once, minimal settings),
//     plus ONE AVCaptureVideoDataOutput for T06 live rectangle
//     detection (alwaysDiscardsLateVideoFrames = true; callbacks on a
//     dedicated serial detection queue, never on this actor's executor
//     or the MainActor).
//   - Idempotent lifecycle: configure once; start many; stop many.
//   - Single in-flight capture: a second capturePhoto() request while
//     one is in flight throws `captureFailed`.
//   - Orientation contract: a capture-side
//     AVCaptureDevice.RotationCoordinator (created after configuration,
//     strongly held) drives videoRotationAngle on the photo-output and
//     video-data-output connections so Vision receives physically
//     upright frames. Only supported angles are written.
//   - NOT configured: metadata output, OCR/text recognition, QR, audio.
//     No microphone permission is ever requested. No flash UI, burst,
//     bracket, RAW, Live Photo, depth or portrait effects.
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
//     the session configured, and any objects added by the failed
//     attempt are removed in reverse order and the transaction
//     committed — the session is left with no partial topology, so a
//     later call retries from a clean state.
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
    /// The video-data output could not be added to the session (T06
    /// live detection).
    case cannotAddVideoDataOutput
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

    /// Live card-detection events (T06). Returns a fresh stream for
    /// the current preview lifecycle; any previously returned stream
    /// is finished first, so re-entering the Scanner never accumulates
    /// stale consumers. `bufferingNewest(1)` backpressure: the consumer
    /// only sees the latest result; stale detections are dropped,
    /// never queued. Only the Sendable value type crosses the
    /// isolation boundary — no CMSampleBuffer and no
    /// VNRectangleObservation ever reaches the consumer. Async because
    /// installing the sample-buffer delegate is session-adjacent work
    /// serialized with the implementation's executor.
    func makeDetectionEvents() async -> AsyncStream<CardRegion?>
}

/// Pure rotation-application decision seam (unit-testable without a
/// real AVCaptureConnection): apply an angle ONLY when the connection
/// reports support for it; otherwise leave the connection untouched —
/// an unsupported angle is never written.
nonisolated enum VideoRotationDecision {
    static func supportedAngle(
        _ angle: CGFloat,
        isSupported: (CGFloat) -> Bool
    ) -> CGFloat? {
        isSupported(angle) ? angle : nil
    }
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

    /// T06 live detection output. Added once inside the same
    /// configuration transaction as the video input and photo output.
    private let videoDataOutput = AVCaptureVideoDataOutput()

    /// Dedicated serial queue for sample-buffer callbacks + Vision
    /// analysis. Never the MainActor, never the camera session queue.
    nonisolated let detectionQueue = DispatchSerialQueue(
        label: "com.metahumanz.SimCamCard.camera.detection"
    )

    /// The stream continuation that feeds the latest detection result
    /// to consumers. Created each time the session starts (or when
    /// `detectionEvents` is read); finished and discarded on stop.
    private var detectionContinuation: AsyncStream<CardRegion?>.Continuation?

    /// Strong reference to the delegate that bridges sample buffers to
    /// the Vision detector. Held so AVFoundation never calls a
    /// deallocated delegate.
    private var detectionProcessor: VideoFrameProcessor?

    /// Rear device captured during configuration. Retained for the
    /// capture-side RotationCoordinator and so the preview view can
    /// later build its own preview RotationCoordinator from the
    /// already-configured stable session (read-only access, no topology
    /// mutation).
    private var rearCameraDevice: AVCaptureDevice?

    /// Capture-side RotationCoordinator. Owned by this actor; updates
    /// the photo-output and video-data-output connections via
    /// `applyCaptureRotation(angle:)`.
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?

    /// KVO observation token for capture-angle changes. Retained so
    /// observation stays alive for the Scanner's lifetime.
    private var rotationObservation: NSKeyValueObservation?

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
        rearCameraDevice = device

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            throw CameraSessionError.noVideoDevice
        }

        // T06: late frames are dropped at the source; this is output
        // configuration, not topology, so it is set before the
        // transaction and stays harmless even if configure fails.
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        // One add/rollback transaction: input → photo output →
        // video-data output. On any rejection the helper removes only
        // the objects this attempt added (reverse order), commits the
        // clean topology and throws the original error, so a later
        // configureIfNeeded() retries from NO partial topology.
        try CameraTopologyTransaction.apply(
            to: session,
            videoInput: input,
            photoOutput: photoOutput,
            videoDataOutput: videoDataOutput
        )

        // RotationCoordinator (capture side): establishes the canonical
        // orientation contract so Vision receives upright frames.
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(
            device: device, previewLayer: nil
        )
        rotationObservation = rotationCoordinator?.observe(
            \.videoRotationAngleForHorizonLevelCapture,
            options: [.new]
        ) { [weak self] _, change in
            guard let angle = change.newValue else { return }
            Task { await self?.applyCaptureRotation(angle: angle) }
        }
        if let angle = rotationCoordinator?.videoRotationAngleForHorizonLevelCapture {
            applyCaptureRotation(angle: angle)
        }

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
        videoDataOutput.setSampleBufferDelegate(nil, queue: nil)
        detectionContinuation?.finish()
        detectionContinuation = nil
        detectionProcessor = nil
    }

    // MARK: - Detection stream

    /// Returns the live detection stream for the current preview
    /// lifecycle. Any previously returned stream is finished first so
    /// re-entering the Scanner never accumulates stale consumers.
    /// `bufferingNewest(1)`: the consumer only sees the latest result.
    ///
    /// Runs on this actor's serial executor: installing the sample
    /// -buffer delegate is a session-adjacent mutation and must not
    /// race configuration/start/stop. The delegate's callbacks then
    /// fire on the separate serial `detectionQueue`.
    func makeDetectionEvents() -> AsyncStream<CardRegion?> {
        detectionContinuation?.finish()
        detectionContinuation = nil
        detectionProcessor = nil

        let (stream, continuation) = AsyncStream<CardRegion?>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        let processor = VideoFrameProcessor(continuation: continuation)
        videoDataOutput.setSampleBufferDelegate(processor, queue: detectionQueue)
        detectionContinuation = continuation
        detectionProcessor = processor
        return stream
    }

    // MARK: - Capture rotation

    /// Applies the current RotationCoordinator capture angle to the
    /// photo-output and video-data-output connections. Runs on this
    /// actor's serial executor (connection mutation is session work).
    /// Only angles the connection reports as supported are written —
    /// an unsupported angle leaves the connection untouched.
    func applyCaptureRotation(angle: CGFloat) {
        for output in [photoOutput, videoDataOutput] {
            guard let connection = output.connection(with: .video),
                  let supported = VideoRotationDecision.supportedAngle(
                      angle, isSupported: connection.isVideoRotationAngleSupported
                  )
            else { continue }
            connection.videoRotationAngle = supported
        }
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
