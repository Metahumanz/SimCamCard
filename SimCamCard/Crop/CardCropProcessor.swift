//
//  CardCropProcessor.swift
//  SimCamCard
//
//  Still-image crop processing service (Week 3 Increment 5 — P04).
//
//  The shared camera-capture AND photo-import still pipeline:
//    CapturedPhoto
//    → decode (ImageIO, orientation resolved)
//    → still-image rectangle detection (reuses CardRegionDetector)
//    → CropDraft
//    → perspective correction (Core Image)
//    → CardCropResult (new upright PNG; original bytes untouched)
//
//  Concurrency: same safe serial model as CameraSessionController —
//  an `actor` on a dedicated DispatchSerialQueue custom executor.
//  Decode, Vision and Core Image work are heavy and never run on the
//  MainActor. Only Sendable project values cross the boundary
//  (CropPreparation / CardCropResult); CIImage and CGImage never leave
//  this actor and are never stored in the ViewModel.
//  NOT `@unchecked Sendable`, NOT `nonisolated(unsafe)`, NOT
//  `Task.detached`.
//

import Foundation
import Dispatch
import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO

/// Abstract crop-processing seam. Allows deterministic unit/UI tests to
/// inject a controllable preparation result while keeping the MainActor
/// ViewModel decoupled from the concrete Core Image service.
nonisolated protocol CardCropProcessing: Sendable {
    /// Decodes `photo`, resolves orientation and runs still rectangle
    /// detection. When detection finds nothing the implementation
    /// returns an inset fallback rectangle with `wasDetected == false`
    /// (manual cropping stays possible). Throws only on undecodable
    /// data.
    func prepare(_ photo: CapturedPhoto) async throws -> CropPreparation

    /// Applies orientation normalization + perspective correction for
    /// `draft` and encodes a new upright PNG. Throws `CropError` on an
    /// invalid region or failed render/encode; the original bytes are
    /// never modified.
    func perspectiveCorrect(_ draft: CropDraft) async throws -> CardCropResult
}

/// Pure conversion from the project's top-left normalized coordinates
/// to Core Image's bottom-left Cartesian coordinates on the UPRIGHT
/// (orientation-normalized) image. Unit-tested independently.
nonisolated enum PerspectiveCoordinateMapping {

    /// Maps one normalized point (origin top-left, y down) into Core
    /// Image pixel coordinates (origin bottom-left, y up) for an image
    /// of the given ORIENTED dimensions.
    static func coreImagePoint(
        normalized: NormalizedPoint,
        orientedWidth: Double,
        orientedHeight: Double
    ) -> CGPoint {
        CGPoint(
            x: normalized.x * orientedWidth,
            y: (1 - normalized.y) * orientedHeight
        )
    }
}

actor CardCropProcessor: CardCropProcessing {

    /// Dedicated serial queue backing this actor's executor: all decode,
    /// Vision and Core Image work is serialized off the MainActor.
    nonisolated let processingQueue = DispatchSerialQueue(
        label: "com.metahumanz.SimCamCard.crop.processing"
    )

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        processingQueue.asUnownedSerialExecutor()
    }

    /// Reused across confirms — CIContext creation is expensive.
    private let ciContext = CIContext()

    /// The Increment 4 stable Vision detector, injected for testability.
    private let detector: any CardRegionDetecting

    init(detector: any CardRegionDetecting = CardRegionDetector()) {
        self.detector = detector
    }

    // MARK: - Preparation

    func prepare(_ photo: CapturedPhoto) throws -> CropPreparation {
        let decoded = try CardImageDecoder.decode(photo.data)

        let draftRegion: CardRegion
        let wasDetected: Bool
        if let detected = detector.detect(
            in: decoded.cgImage,
            orientation: decoded.orientation
        ), CardRegionGeometry.isAcceptableAutoDetection(detected) {
            draftRegion = detected
            wasDetected = true
        } else {
            // Implementation robustness fallback (NOT Reference-observed
            // behavior): an inset rectangle keeps manual cropping
            // possible; the ViewModel enters manualAdjusting. Also covers
            // detected-but-too-small quads (conservative rejection).
            draftRegion = CardRegionGeometry.fallbackRegion(
                pixelWidth: decoded.orientedPixelWidth,
                pixelHeight: decoded.orientedPixelHeight
            )
            wasDetected = false
        }

        let draft = CropDraft(
            source: photo,
            sourceOrientation: decoded.orientation,
            sourcePixelWidth: decoded.orientedPixelWidth,
            sourcePixelHeight: decoded.orientedPixelHeight,
            region: draftRegion
        )
        return CropPreparation(draft: draft, wasDetected: wasDetected)
    }

    // MARK: - Perspective correction

    func perspectiveCorrect(_ draft: CropDraft) throws -> CardCropResult {
        guard CardRegionGeometry.isValid(draft.region) else {
            throw CropError.invalidRegion
        }

        let decoded: DecodedImage
        do {
            decoded = try CardImageDecoder.decode(draft.source.data)
        } catch let error as CropError {
            throw error
        }

        // Orientation normalization BEFORE geometry: work on the
        // physically upright image, never on raw sensor orientation.
        var oriented = CIImage(cgImage: decoded.cgImage)
            .oriented(decoded.orientation)

        // Some orientation/cropping chains leave a non-zero extent
        // origin; normalize to (0,0) before corner mapping.
        let extent = oriented.extent
        if extent.origin != .zero {
            oriented = oriented.transformed(
                by: CGAffineTransform(
                    translationX: -extent.origin.x,
                    y: -extent.origin.y
                )
            )
        }
        let uprightExtent = oriented.extent
        let width = uprightExtent.width
        let height = uprightExtent.height
        guard width > 0, height > 0 else {
            throw CropError.correctionFailed
        }

        // CardRegion (top-left, y-down) → Core Image (bottom-left,
        // y-up) on the upright image. Corner labels map 1:1.
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = oriented
        filter.topLeft = PerspectiveCoordinateMapping.coreImagePoint(
            normalized: draft.region.topLeft, orientedWidth: width, orientedHeight: height
        )
        filter.topRight = PerspectiveCoordinateMapping.coreImagePoint(
            normalized: draft.region.topRight, orientedWidth: width, orientedHeight: height
        )
        filter.bottomLeft = PerspectiveCoordinateMapping.coreImagePoint(
            normalized: draft.region.bottomLeft, orientedWidth: width, orientedHeight: height
        )
        filter.bottomRight = PerspectiveCoordinateMapping.coreImagePoint(
            normalized: draft.region.bottomRight, orientedWidth: width, orientedHeight: height
        )
        filter.crop = true

        guard let output = filter.outputImage,
              output.extent.width > 0,
              output.extent.height > 0,
              let rendered = ciContext.createCGImage(output, from: output.extent),
              rendered.width > 0,
              rendered.height > 0
        else {
            throw CropError.correctionFailed
        }

        let pngData = try encodePNG(rendered)

        return CardCropResult(
            original: draft.source,
            confirmedRegion: draft.region,
            processedImageData: pngData,
            processedPixelWidth: rendered.width,
            processedPixelHeight: rendered.height
        )
    }

    /// Encodes one CGImage as a deterministic, lossless PNG with NO
    /// orientation metadata — the pixels are already physically
    /// upright, so the processed image's orientation semantics are
    /// `.up`.
    private func encodePNG(_ cgImage: CGImage) throws -> Data {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, "public.png" as CFString, 1, nil
        ) else {
            throw CropError.correctionFailed
        }
        // No properties dictionary: no EXIF orientation is written.
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination), output.length > 0 else {
            throw CropError.correctionFailed
        }
        return output as Data
    }
}
