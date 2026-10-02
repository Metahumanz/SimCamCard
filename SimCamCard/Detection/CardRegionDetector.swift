//
//  CardRegionDetector.swift
//  SimCamCard
//
//  Vision rectangle detector (Week 3 Increment 4 — T06 automatic live
//  boundary detection).
//
//  Uses the stable Vision rectangle-detection API
//  (VNDetectRectanglesRequest / VNRectangleObservation) — Apple lists
//  business cards among its intended subjects. Beta/experimental
//  Swift-native Vision APIs are deliberately NOT used as the core
//  dependency in this increment.
//
//  Vision framework objects are confined to this detector: callers
//  only ever receive the project-owned Sendable `CardRegion?`. This
//  keeps a future Vision API migration from touching the
//  ViewModel/View.
//
//  Error contract: a Vision failure produces `nil` for that frame —
//  never an error state, never cameraUnavailable; the scanner stays
//  usable (the camera may be perfectly healthy while one analysis
//  fails).
//
//  Geometry only: no OCR/text content is used to assist detection.
//

import CoreGraphics
import CoreVideo
import Vision

nonisolated struct CardRegionDetector: Sendable {

    /// Business-card detection thresholds, centralized (no magic
    /// numbers scattered in delegates). Single-card scanning → at most
    /// one observation.
    ///
    /// Vision aspect-ratio semantics (VNDetectRectanglesRequest): both
    /// `minimumAspectRatio` and `maximumAspectRatio` are defined as
    /// SHORTER dimension / LONGER dimension, so every legal value lies
    /// in 0...1. A ratio > 1 is invalid; horizontal and vertical cards
    /// share the SAME ratio range (no reciprocal needed). The
    /// 0.4...1.0 window covers business-card ratios (~0.57–0.63 for
    /// both orientations) with slack for perspective skew. Calibrated
    /// against the project dataset smoke tests (card-001/007/013),
    /// not tuned to any single card.
    struct Configuration: Sendable, Equatable {
        var maximumObservations: Int = 1
        var minimumConfidence: Float = 0.6
        var minimumSize: Float = 0.1
        var minimumAspectRatio: Float = 0.4
        var maximumAspectRatio: Float = 1.0
        var quadratureTolerance: Float = 30

        static let businessCardBaseline = Configuration()
    }

    let configuration: Configuration

    init(configuration: Configuration = .businessCardBaseline) {
        self.configuration = configuration
    }

    /// Runs rectangle detection on one upright video frame. The caller
    /// guarantees the pixel buffer is already physically
    /// rotation-corrected by the capture connection, so Vision always
    /// receives `.up`.
    func detect(
        in pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation = .up
    ) -> CardRegion? {
        let request = makeRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do {
            try handler.perform([request])
        } catch {
            // Vision failure → no detected region for this frame. Not a
            // camera error; the scanner remains usable.
            return nil
        }
        return cardRegion(
            from: request.results,
            sourcePixelWidth: CVPixelBufferGetWidth(pixelBuffer),
            sourcePixelHeight: CVPixelBufferGetHeight(pixelBuffer)
        )
    }

    /// Runs rectangle detection on a still image (dataset smoke tests
    /// and the later captured/imported-image pipeline). `orientation`
    /// is the resolved metadata orientation of the bytes; the reported
    /// source pixel size is the ORIENTED size (width/height swap for
    /// 90°/270° orientations) so overlay mapping stays correct.
    func detect(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) -> CardRegion? {
        let request = makeRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        let swapsAxes: Bool = switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored: true
        default: false
        }
        return cardRegion(
            from: request.results,
            sourcePixelWidth: swapsAxes ? cgImage.height : cgImage.width,
            sourcePixelHeight: swapsAxes ? cgImage.width : cgImage.height
        )
    }

    // MARK: - Private

    private func makeRequest() -> VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = configuration.maximumObservations
        request.minimumConfidence = configuration.minimumConfidence
        request.minimumSize = configuration.minimumSize
        request.minimumAspectRatio = configuration.minimumAspectRatio
        request.maximumAspectRatio = configuration.maximumAspectRatio
        request.quadratureTolerance = configuration.quadratureTolerance
        return request
    }

    /// Converts the single best Vision observation to the
    /// project-owned value. Vision objects never escape this detector.
    private func cardRegion(
        from results: [VNRectangleObservation]?,
        sourcePixelWidth: Int,
        sourcePixelHeight: Int
    ) -> CardRegion? {
        guard let observation = results?.first else { return nil }
        return CardRegion(
            visionTopLeft: observation.topLeft,
            visionTopRight: observation.topRight,
            visionBottomRight: observation.bottomRight,
            visionBottomLeft: observation.bottomLeft,
            sourcePixelWidth: sourcePixelWidth,
            sourcePixelHeight: sourcePixelHeight
        )
    }
}
