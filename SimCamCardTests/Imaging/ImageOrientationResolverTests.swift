//
//  ImageOrientationResolverTests.swift
//  SimCamCardTests
//
//  Unit tests for ImageOrientationResolver (Week 3 Increment 4).
//
//  Contract under test:
//   - EXIF/TIFF orientation metadata → CGImagePropertyOrientation
//   - missing orientation metadata → .up
//   - invalid / non-image data → .up (defined default contract)
//
//  Fixtures are tiny in-memory images written with CGImageDestination
//  (ImageIO) so orientation metadata is injected directly — no UIKit
//  image normalization is involved anywhere in the test.
//

import Foundation
import ImageIO
import Testing
@testable import SimCamCard

@Suite("ImageOrientationResolver")
struct ImageOrientationResolverTests {

    /// Builds a minimal 2×2 8-bit image encoded as PNG with the given
    /// EXIF orientation metadata (nil = no orientation key). Returns
    /// nil only if the platform image stack cannot encode (a test
    /// infrastructure failure, surfaced via #require at call sites).
    private static func makeImageData(
        orientation: UInt32?
    ) -> Data? {
        let width = 2, height = 2
        var pixels = [UInt8](repeating: 0x80, count: width * height * 4)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        ), let image = context.makeImage() else {
            return nil
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData, "public.png" as CFString, 1, nil
        ) else {
            return nil
        }
        var properties: [CFString: Any] = [:]
        if let orientation {
            properties[kCGImagePropertyOrientation] = orientation
        }
        CGImageDestinationAddImage(
            destination, image, properties as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }

    // MARK: - Orientation metadata mapping

    @Test("EXIF orientation maps to CGImagePropertyOrientation", arguments: [
        (UInt32(1), CGImagePropertyOrientation.up),
        (3, .down),
        (6, .right),
        (8, .left),
    ])
    func orientationMetadataMapsToCGImagePropertyOrientation(
        rawValue: UInt32,
        expected: CGImagePropertyOrientation
    ) throws {
        let data = try #require(Self.makeImageData(orientation: rawValue))
        #expect(ImageOrientationResolver.orientation(of: data) == expected)
    }

    // MARK: - Missing metadata → .up

    @Test("image without orientation metadata resolves to .up")
    func missingOrientationDefaultsToUp() throws {
        let data = try #require(Self.makeImageData(orientation: nil))
        #expect(ImageOrientationResolver.orientation(of: data) == .up)
    }

    // MARK: - Invalid image → .up (defined default)

    @Test("non-image data resolves to .up")
    func invalidDataDefaultsToUp() {
        #expect(ImageOrientationResolver.orientation(of: Data([0x00, 0x01, 0x02])) == .up)
        #expect(ImageOrientationResolver.orientation(of: Data()) == .up)
    }
}
