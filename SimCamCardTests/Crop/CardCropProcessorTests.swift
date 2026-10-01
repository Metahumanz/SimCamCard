//
//  CardCropProcessorTests.swift
//  SimCamCardTests
//
//  Unit tests for the shared still crop pipeline
//  (Week 3 Increment 5):
//
//    synthetic Data → CardImageDecoder → (manual CropDraft)
//    → CardCropProcessor.perspectiveCorrect → upright PNG
//
//  No UIKit, no UI: every fixture is a hand-built RGBA bitmap encoded
//  with ImageIO. Real photograph coverage lives in
//  CropPipelineDatasetSmokeTests.
//

import Foundation
import ImageIO
import CoreGraphics
import Testing
@testable import SimCamCard

@Suite("CardCropProcessor")
struct CardCropProcessorTests {

    // MARK: - Axis-aligned correction

    @Test("axis-aligned inset region corrects into a decodable upright PNG")
    func axisAlignedInsetCorrectionSucceeds() async throws {
        let processor = CardCropProcessor()
        let data = try Self.makeImageData(width: 240, height: 180)
        let photo = CapturedPhoto(data: data)
        let region = Self.region(
            tl: (0.20, 0.25), tr: (0.80, 0.25),
            br: (0.80, 0.75), bl: (0.20, 0.75),
            pixelWidth: 240, pixelHeight: 180
        )
        let draft = CropDraft(
            source: photo,
            sourceOrientation: .up,
            sourcePixelWidth: 240,
            sourcePixelHeight: 180,
            region: region
        )

        let result = try await processor.perspectiveCorrect(draft)

        #expect(result.original == photo)
        #expect(result.confirmedRegion == region)
        #expect(result.processedPixelWidth > 0)
        #expect(result.processedPixelHeight > 0)
        // Expected output is roughly 60% x 50% of the source.
        #expect(result.processedPixelWidth < 240)
        #expect(result.processedPixelHeight < 180)

        // The output must be a valid PNG with no orientation metadata:
        // pixels are already physically upright.
        let decoded = try CardImageDecoder.decode(result.processedImageData)
        #expect(decoded.orientation == .up)
        #expect(decoded.orientedPixelWidth == result.processedPixelWidth)
        #expect(decoded.orientedPixelHeight == result.processedPixelHeight)
    }

    // MARK: - Perspective correction

    @Test("perspective quadrilateral correction succeeds")
    func perspectiveQuadCorrectionSucceeds() async throws {
        let processor = CardCropProcessor()
        let data = try Self.makeImageData(width: 300, height: 200)
        let photo = CapturedPhoto(data: data)
        let region = Self.region(
            tl: (0.22, 0.28), tr: (0.84, 0.22),
            br: (0.78, 0.80), bl: (0.26, 0.86),
            pixelWidth: 300, pixelHeight: 200
        )
        let draft = CropDraft(
            source: photo,
            sourceOrientation: .up,
            sourcePixelWidth: 300,
            sourcePixelHeight: 200,
            region: region
        )

        let result = try await processor.perspectiveCorrect(draft)

        #expect(result.processedPixelWidth > 0)
        #expect(result.processedPixelHeight > 0)
        let decoded = try CardImageDecoder.decode(result.processedImageData)
        #expect(decoded.orientation == .up)
    }

    // MARK: - Invalid inputs

    @Test("prepare with non-image bytes throws invalidImageData")
    func prepareInvalidDataThrows() async {
        let processor = CardCropProcessor()
        let photo = CapturedPhoto(data: Data([0x01, 0x02, 0x03]))
        await #expect(throws: CropError.invalidImageData) {
            _ = try await processor.prepare(photo)
        }
    }

    @Test("correction with non-image bytes throws invalidImageData")
    func correctInvalidDataThrows() async {
        let processor = CardCropProcessor()
        let photo = CapturedPhoto(data: Data([0x01, 0x02, 0x03]))
        let draft = CropDraft(
            source: photo,
            sourceOrientation: .up,
            sourcePixelWidth: 240,
            sourcePixelHeight: 180,
            region: Self.fallbackLikeRegion(pixelWidth: 240, pixelHeight: 180)
        )
        await #expect(throws: CropError.invalidImageData) {
            _ = try await processor.perspectiveCorrect(draft)
        }
    }

    @Test("correction with an invalid region throws invalidRegion")
    func correctInvalidRegionThrows() async throws {
        let processor = CardCropProcessor()
        let data = try Self.makeImageData(width: 240, height: 180)
        let photo = CapturedPhoto(data: data)
        // Collapsed zero-area region.
        let region = Self.region(
            tl: (0.5, 0.5), tr: (0.5, 0.5),
            br: (0.5, 0.5), bl: (0.5, 0.5),
            pixelWidth: 240, pixelHeight: 180
        )
        let draft = CropDraft(
            source: photo,
            sourceOrientation: .up,
            sourcePixelWidth: 240,
            sourcePixelHeight: 180,
            region: region
        )
        await #expect(throws: CropError.invalidRegion) {
            _ = try await processor.perspectiveCorrect(draft)
        }
    }

    // MARK: - Preparation

    @Test("prepare decodes and reports oriented dimensions")
    func prepareReportsOrientedDims() async throws {
        let processor = CardCropProcessor()
        let data = try Self.makeImageData(width: 240, height: 180)
        let photo = CapturedPhoto(data: data)

        let preparation = try await processor.prepare(photo)

        #expect(preparation.draft.sourcePixelWidth == 240)
        #expect(preparation.draft.sourcePixelHeight == 180)
        #expect(preparation.draft.sourceOrientation == .up)
        // A synthetic flat-contrast fixture is not required to detect;
        // whichever outcome, the region must be usable and the draft
        // source untouched.
        #expect(CardRegionGeometry.isValid(preparation.draft.region))
        #expect(preparation.draft.source == photo)
    }

    // MARK: - EXIF orientation end to end

    @Test("EXIF .right source is corrected into physically-upright landscape PNG")
    func exifRightCorrectionIsPhysicallyUpright() async throws {
        let processor = CardCropProcessor()
        // Portrait-encoded bitmap (100 wide, 200 tall) marked EXIF 6
        // (.right): after orientation normalization the upright image
        // is 200 wide x 100 tall.
        let data = try Self.makeImageData(width: 100, height: 200, orientation: 6)
        let photo = CapturedPhoto(data: data)

        // Sanity: the source bytes really carry .right and are NOT
        // physically upright yet.
        #expect(ImageOrientationResolver.orientation(of: data) == .right)
        let rawDecoded = try CardImageDecoder.decode(data)
        #expect(rawDecoded.orientedPixelWidth == 200)
        #expect(rawDecoded.orientedPixelHeight == 100)

        let region = Self.region(
            tl: (0.15, 0.15), tr: (0.85, 0.15),
            br: (0.85, 0.85), bl: (0.15, 0.85),
            pixelWidth: 200, pixelHeight: 100
        )
        let draft = CropDraft(
            source: photo,
            sourceOrientation: .right,
            sourcePixelWidth: 200,
            sourcePixelHeight: 100,
            region: region
        )

        let result = try await processor.perspectiveCorrect(draft)

        // The corrected image must be landscape (axes swapped exactly
        // once) and carry no residual EXIF rotation.
        #expect(result.processedPixelWidth > result.processedPixelHeight)
        let decoded = try CardImageDecoder.decode(result.processedImageData)
        #expect(decoded.orientation == .up)

        // The original bytes are immutable: same length and still .right.
        #expect(result.original.data == data)
        #expect(ImageOrientationResolver.orientation(of: result.original.data) == .right)
    }

    // MARK: - Helpers

    private static func region(
        tl: (Double, Double),
        tr: (Double, Double),
        br: (Double, Double),
        bl: (Double, Double),
        pixelWidth: Int,
        pixelHeight: Int
    ) -> CardRegion {
        CardRegion(
            topLeft: NormalizedPoint(x: tl.0, y: tl.1),
            topRight: NormalizedPoint(x: tr.0, y: tr.1),
            bottomRight: NormalizedPoint(x: br.0, y: br.1),
            bottomLeft: NormalizedPoint(x: bl.0, y: bl.1),
            sourcePixelWidth: pixelWidth,
            sourcePixelHeight: pixelHeight
        )
    }

    private static func fallbackLikeRegion(pixelWidth: Int, pixelHeight: Int) -> CardRegion {
        CardRegionGeometry.fallbackRegion(pixelWidth: pixelWidth, pixelHeight: pixelHeight)
    }

    /// Builds an RGBA bitmap (dark surround, lighter central panel)
    /// and encodes it as PNG, optionally with EXIF orientation
    /// metadata. The panel gives the correction filter real
    /// high-frequency edges instead of a uniform image.
    fileprivate static func makeImageData(
        width: Int,
        height: Int,
        orientation: UInt32? = nil
    ) throws -> Data {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                let inside = x >= width / 5 && x < width * 4 / 5
                    && y >= height / 5 && y < height * 4 / 5
                let value: UInt8 = inside ? 0xE6 : 0x1A
                pixels[index] = value
                pixels[index + 1] = value
                pixels[index + 2] = value
                pixels[index + 3] = 0xFF
            }
        }
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = context.makeImage() else {
            throw CropError.correctionFailed
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, "public.png" as CFString, 1, nil
        ) else {
            throw CropError.correctionFailed
        }
        if let orientation {
            let properties: [CFString: Any] = [
                kCGImagePropertyOrientation: orientation
            ]
            CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        } else {
            CGImageDestinationAddImage(destination, image, nil)
        }
        guard CGImageDestinationFinalize(destination), output.length > 0 else {
            throw CropError.correctionFailed
        }
        return output as Data
    }
}
