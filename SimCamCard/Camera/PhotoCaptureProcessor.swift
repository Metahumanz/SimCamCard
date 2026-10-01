//
//  PhotoCaptureProcessor.swift
//  SimCamCard
//
//  AVCapturePhotoCaptureDelegate bridge for one in-flight still
//  capture (Week 3 Increment 2 — T04 still capture).
//
//  Lifetime contract (prompt §7): an instance is created per capture
//  request and is STRONGLY HELD by CameraSessionController in its
//  `inFlightCapture` property until the delegate callback resumes the
//  continuation — the delegate can never be deallocated mid-capture,
//  and the reference is cleared on completion (exactly-once resume).
//
//  Sendable boundary: `AVCapturePhoto` is non-Sendable in this SDK
//  and is NEVER stored or passed across actor boundaries. The
//  delegate callback (which arrives on an AVFoundation queue via the
//  @preconcurrency import bridge — compile-time relaxation only)
//  converts it to `Data` IMMEDIATELY via `fileDataRepresentation()`
//  and resumes the continuation with the Sendable CapturedPhoto.
//  Only that value crosses back to the CameraSessionController actor
//  and then to the MainActor ScanViewModel.
//

@preconcurrency import AVFoundation

/// One-shot photo capture delegate: resumes its continuation exactly
/// once, with either a CapturedPhoto or a CameraSessionError.
///
/// `nonisolated`: the project's SWIFT_DEFAULT_ACTOR_ISOLATION =
/// MainActor would otherwise pin this NSObject subclass (and its
/// delegate conformance) to the MainActor, making it unusable from the
/// CameraSessionController actor. The only state is the immutable
/// continuation let, so nonisolated is safe and exact — no
/// `@unchecked Sendable`, no `nonisolated(unsafe)`.
nonisolated final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {

    /// Resumed exactly once from the AVFoundation delegate callback.
    private let continuation: CheckedContinuation<CapturedPhoto, Error>

    init(continuation: CheckedContinuation<CapturedPhoto, Error>) {
        self.continuation = continuation
        super.init()
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        if error != nil {
            continuation.resume(throwing: CameraSessionError.captureFailed)
            return
        }
        // Convert to raw bytes NOW, inside the callback; the
        // AVCapturePhoto object itself never leaves this scope.
        guard let data = photo.fileDataRepresentation(), !data.isEmpty else {
            continuation.resume(throwing: CameraSessionError.emptyPhotoData)
            return
        }
        continuation.resume(returning: CapturedPhoto(data: data))
    }
}
