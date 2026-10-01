//
//  CardRegionDetectorTests.swift
//  SimCamCardTests
//
//  Real-Vision dataset smoke tests (Week 3 Increment 4 — T06).
//
//  These tests run the REAL VNDetectRectanglesRequest (no fake) on
//  three representative frozen-dataset images:
//    card-001  standard horizontal bilingual
//    card-007  vertical
//    card-013  photographed / non-flat-style source
//
//  The dataset has NO card-corner ground truth, so the assertion is
//  deliberately a smoke contract, not pixel-perfect geometry:
//    - detector returns exactly one valid quadrilateral
//    - all normalized points inside [0,1]
//    - quadrilateral area above a trivial threshold
//
//  The dataset is read in place via #filePath → repository root. The
//  dataset is never copied into the test target and never modified.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import SimCamCard

@Suite("CardRegionDetector (real Vision, dataset smoke)")
struct CardRegionDetectorTests {

    /// Repository root derived from this file's path:
    /// <root>/SimCamCardTests/Detection/CardRegionDetectorTests.swift
    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Detection/
        .deletingLastPathComponent()  // SimCamCardTests/
        .deletingLastPathComponent()  // <root>

    private static func loadCGImage(named name: String) throws -> (CGImage, CGImagePropertyOrientation) {
        let url = repoRoot.appending(path: "dataset/cards/\(name)")
        let data = try Data(contentsOf: url)
        let source = CGImageSourceCreateWithData(data as CFData, nil)
        #expect(source != nil, "dataset image must be readable: \(name)")
        guard let source, let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            Issue.record("failed to decode dataset image \(name)")
            throw CocoaError(.coderReadCorrupt)
        }
        return (image, ImageOrientationResolver.orientation(of: data))
    }

    /// Shoelace area of the quadrilateral in normalized units.
    private static func quadrilateralArea(_ region: CardRegion) -> Double {
        let points = [region.topLeft, region.topRight, region.bottomRight, region.bottomLeft]
        var area = 0.0
        for index in points.indices {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            area += a.x * b.y - b.x * a.y
        }
        return abs(area) / 2
    }

    private static func assertValidDetection(in imageName: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let (image, orientation) = try loadCGImage(named: imageName)
        let detector = CardRegionDetector()

        let detected = detector.detect(in: image, orientation: orientation)

        let region = try #require(detected, "detector must return a quadrilateral for \(imageName)", sourceLocation: sourceLocation)
        for point in [region.topLeft, region.topRight, region.bottomRight, region.bottomLeft] {
            #expect((0...1).contains(point.x), "x in [0,1] for \(imageName)", sourceLocation: sourceLocation)
            #expect((0...1).contains(point.y), "y in [0,1] for \(imageName)", sourceLocation: sourceLocation)
        }
        // The card dominates each dataset frame; require a clearly
        // non-trivial area (>> 1% of the image).
        #expect(quadrilateralArea(region) > 0.05, "non-trivial area for \(imageName)", sourceLocation: sourceLocation)
        #expect(region.sourcePixelWidth > 0 && region.sourcePixelHeight > 0, sourceLocation: sourceLocation)
    }

    @Test("card-001 standard horizontal → one valid quadrilateral")
    func detectsStandardHorizontalCard() throws {
        try Self.assertValidDetection(in: "card-001-standard-bilingual.png")
    }

    @Test("card-007 vertical → one valid quadrilateral")
    func detectsVerticalCard() throws {
        try Self.assertValidDetection(in: "card-007-vertical-medical-bilingual.png")
    }

    @Test("card-013 photographed source → one valid quadrilateral")
    func detectsPhotographedCard() throws {
        try Self.assertValidDetection(in: "card-013-english-bio-photographed.png")
    }

    // MARK: - Configuration contract

    /// The baseline configuration must stay within Vision's documented
    /// legal ranges. In particular, VNDetectRectanglesRequest aspect
    /// ratios are shorter/longer dimension and therefore legal only in
    /// 0...1. This does NOT assert Vision's undocumented internal
    /// clamping — it asserts OUR configured values are legal before
    /// they are handed to the request.
    @Test("business-card baseline configuration respects Vision legal ranges")
    func baselineConfigurationIsLegal() {
        let config = CardRegionDetector.Configuration.businessCardBaseline

        #expect(config.maximumObservations == 1)
        #expect((0...1).contains(config.minimumConfidence))
        #expect((0...1).contains(config.minimumSize))
        #expect(config.minimumAspectRatio >= 0)
        #expect(config.maximumAspectRatio <= 1)
        #expect(config.minimumAspectRatio <= config.maximumAspectRatio)
        #expect((0...45).contains(config.quadratureTolerance))
    }

    // MARK: - Vision error / no-card contract

    @Test("a featureless image yields nil, not an error")
    func featurelessImageYieldsNil() throws {
        // A uniform 64×64 gray image contains no rectangle: the
        // detector must return nil (cardNotDetected), never throw.
        let width = 64, height = 64
        var pixels = [UInt8](repeating: 0x80, count: width * height * 4)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        )
        let image = try #require(context?.makeImage(), "test fixture image must be constructible")

        let detector = CardRegionDetector()
        #expect(detector.detect(in: image, orientation: .up) == nil)
    }
}
