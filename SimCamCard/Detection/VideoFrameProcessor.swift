//
//  VideoFrameProcessor.swift
//  SimCamCard
//
//  AVCaptureVideoDataOutputSampleBufferDelegate → Vision bridge
//  (Week 3 Increment 4 — T06 live detection).
//
//  Responsibilities (strictly bounded):
//   - consume CMSampleBuffers on the dedicated serial DETECTION queue
//     (com.metahumanz.SimCamCard.camera.detection — never the MainActor,
//     never the camera session queue);
//   - run the CardRegionDetector on each frame;
//   - publish only the Sendable value-type result `CardRegion?` into an
//     AsyncStream.bufferingNewest(1) — the ViewModel cares only about
//     the latest boundary, so stale frames are dropped rather than
//     queued (with alwaysDiscardsLateVideoFrames there is no backlog).
//
//  It does NOT own the AVCaptureSession lifecycle, does NOT update
//  SwiftUI, does NOT create BusinessCards, and does NOT crop/OCR.
//
//  CMSampleBuffer lifetime: consumed synchronously inside the callback
//  and never stored or sent across an isolation boundary. Only the
//  Sendable CardRegion? crosses to the MainActor consumer.
//
//  `nonisolated` (same pattern as PhotoCaptureProcessor): the project's
//  SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor would otherwise pin this
//  NSObject subclass to the MainActor. All state is immutable and
//  Sendable (the detector is a value type; the stream continuation is
//  Sendable), and callbacks are serialized on the detection queue —
//  no `@unchecked Sendable`, no `nonisolated(unsafe)`.
//

@preconcurrency import AVFoundation
import Vision

nonisolated final class VideoFrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    private let detector: CardRegionDetector
    private let continuation: AsyncStream<CardRegion?>.Continuation

    init(
        detector: CardRegionDetector = CardRegionDetector(),
        continuation: AsyncStream<CardRegion?>.Continuation
    ) {
        self.detector = detector
        self.continuation = continuation
        super.init()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            continuation.yield(nil)
            return
        }
        // The video-data-output connection is physically
        // rotation-corrected via the RotationCoordinator capture angle,
        // so Vision receives an upright frame: orientation = .up.
        let region = detector.detect(in: pixelBuffer, orientation: .up)
        continuation.yield(region)
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Late-frame drops are the intended backpressure policy
        // (alwaysDiscardsLateVideoFrames = true); nothing to publish.
    }
}
