//
//  PerspectiveCoordinateMappingTests.swift
//  SimCamCardTests
//
//  Unit tests for the normalized (top-left, y-down) → Core Image
//  (bottom-left, y-up) coordinate mapping, plus the decoder's
//  ORIENTED dimension swap for 90°/270° metadata
//  (Week 3 Increment 5).
//
//  These guard against two classic double-transform bugs:
//   - applying the y-flip twice
//   - swapping width/height twice for .left/.right images
//

import Foundation
import ImageIO
import CoreGraphics
import Testing
@testable import SimCamCard

@Suite("PerspectiveCoordinateMapping")
struct PerspectiveCoordinateMappingTests {

    private static let accuracy = 1e-9

    // MARK: - Y axis conversion

    @Test("normalized origin maps to Core Image bottom-left")
    func topLeftNormalizedMapsToBottomLeftCI() {
        let ci = PerspectiveCoordinateMapping.coreImagePoint(
            normalized: NormalizedPoint(x: 0, y: 0),
            orientedWidth: 200, orientedHeight: 100
        )
        #expect(ci.x == 0)
        #expect(ci.y == 100)
    }

    @Test("normalized bottom-right maps to Core Image top-right")
    func bottomRightNormalizedMapsToTopRightCI() {
        let ci = PerspectiveCoordinateMapping.coreImagePoint(
            normalized: NormalizedPoint(x: 1, y: 1),
            orientedWidth: 200, orientedHeight: 100
        )
        #expect(ci.x == 200)
        #expect(ci.y == 0)
    }

    @Test("normalized center maps to the Core Image center")
    func centerMapsToCenter() {
        let ci = PerspectiveCoordinateMapping.coreImagePoint(
            normalized: NormalizedPoint(x: 0.5, y: 0.5),
            orientedWidth: 200, orientedHeight: 100
        )
        #expect(abs(ci.x - 100) < Self.accuracy)
        #expect(abs(ci.y - 50) < Self.accuracy)
    }

    // MARK: - Oriented dimensions (parameterized orientations)

    @Test("decoder reports oriented dimensions per EXIF orientation", arguments: [
        // (raw EXIF value, raw encoded w/h, expected ORIENTED w/h)
        (UInt32(1), 100, 200, 100, 200),  // .up:    no swap
        (UInt32(3), 100, 200, 100, 200),  // .down:  180°, no swap
        (UInt32(6), 100, 200, 200, 100),  // .right: 90°, swap
        (UInt32(8), 100, 200, 200, 100),  // .left:  270°, swap
    ])
    func orientedDimensions(
        rawOrientation: UInt32,
        encodedWidth: Int,
        encodedHeight: Int,
        expectedWidth: Int,
        expectedHeight: Int
    ) throws {
        let data = try #require(Self.makeImageData(
            width: encodedWidth, height: encodedHeight, orientation: rawOrientation
        ))
        let decoded = try CardImageDecoder.decode(data)
        #expect(decoded.orientedPixelWidth == expectedWidth)
        #expect(decoded.orientedPixelHeight == expectedHeight)
        #expect(decoded.cgImage.width == encodedWidth)
        #expect(decoded.cgImage.height == encodedHeight)
    }

    // MARK: - Mapping on swapped (landscape-after-rotation) axes

    @Test("corner mapping uses oriented dimensions after axis swap")
    func mappingOnSwappedAxes() {
        // A portrait-encoded image with EXIF 6 becomes landscape when
        // upright: oriented 200 wide x 100 tall. The mapping must use
        // the oriented dimensions (no second swap, no missing one).
        let topLeft = PerspectiveCoordinateMapping.coreImagePoint(
            normalized: NormalizedPoint(x: 0, y: 0),
            orientedWidth: 200, orientedHeight: 100
        )
        #expect(topLeft == CGPoint(x: 0, y: 100))

        let bottomRight = PerspectiveCoordinateMapping.coreImagePoint(
            normalized: NormalizedPoint(x: 1, y: 1),
            orientedWidth: 200, orientedHeight: 100
        )
        #expect(bottomRight == CGPoint(x: 200, y: 0))
    }

    // MARK: - Invalid data

    @Test("decoder throws invalidImageData for non-image bytes")
    func decoderRejectsInvalidBytes() {
        #expect(throws: CropError.invalidImageData) {
            _ = try CardImageDecoder.decode(Data([0x01, 0x02, 0x03]))
        }
    }

    // MARK: - Fixture builder

    /// Encodes an RGBA 8-bit PNG of the given size with the given EXIF
    /// orientation property.
    private static func makeImageData(
        width: Int,
        height: Int,
        orientation: UInt32
    ) -> Data? {
        var pixels = [UInt8](repeating: 0x80, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = context.makeImage() else {
            return nil
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, "public.png" as CFString, 1, nil
        ) else {
            return nil
        }
        let properties: [CFString: Any] = [
            kCGImagePropertyOrientation: orientation
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
