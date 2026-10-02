//
//  CardRegionTests.swift
//  SimCamCardTests
//
//  Unit tests for the CardRegion coordinate convention
//  (Week 3 Increment 4):
//   - Vision lower-left origin → SimCamCard top-left origin
//     (appY = 1 − visionY per corner)
//   - all points clamped to [0,1]
//   - corner ordering preserved (TL stays TL, etc.)
//

import CoreGraphics
import Testing
@testable import SimCamCard

@Suite("CardRegion")
struct CardRegionTests {

    /// Epsilon comparison: `1 − visionY` is binary floating-point
    /// arithmetic, so exact equality with a decimal literal would
    /// freeze an unspecified FP artifact. Only the conversion MEANING
    /// is specified.
    private static func expectClose(
        _ point: NormalizedPoint, x: Double, y: Double,
        accuracy: Double = 1e-9
    ) {
        #expect(abs(point.x - x) <= accuracy)
        #expect(abs(point.y - y) <= accuracy)
    }

    @Test("Vision lower-left coordinates convert to top-left origin")
    func visionToTopLeftConversion() {
        // Vision: origin bottom-left, y up. A corner at vision y=0.9 is
        // near the TOP of the image → app y = 0.1.
        let region = CardRegion(
            visionTopLeft: CGPoint(x: 0.1, y: 0.9),
            visionTopRight: CGPoint(x: 0.9, y: 0.9),
            visionBottomRight: CGPoint(x: 0.9, y: 0.1),
            visionBottomLeft: CGPoint(x: 0.1, y: 0.1),
            sourcePixelWidth: 1000,
            sourcePixelHeight: 500
        )

        Self.expectClose(region.topLeft, x: 0.1, y: 0.1)
        Self.expectClose(region.topRight, x: 0.9, y: 0.1)
        Self.expectClose(region.bottomRight, x: 0.9, y: 0.9)
        Self.expectClose(region.bottomLeft, x: 0.1, y: 0.9)
        #expect(region.sourcePixelWidth == 1000)
        #expect(region.sourcePixelHeight == 500)
    }

    @Test("corner ordering is preserved through the conversion")
    func cornerOrderingPreserved() {
        // Distinct values per corner prove labels are not swapped.
        let region = CardRegion(
            visionTopLeft: CGPoint(x: 0.11, y: 0.88),
            visionTopRight: CGPoint(x: 0.77, y: 0.86),
            visionBottomRight: CGPoint(x: 0.79, y: 0.22),
            visionBottomLeft: CGPoint(x: 0.13, y: 0.24),
            sourcePixelWidth: 100,
            sourcePixelHeight: 100
        )

        Self.expectClose(region.topLeft, x: 0.11, y: 0.12)
        Self.expectClose(region.topRight, x: 0.77, y: 0.14)
        Self.expectClose(region.bottomRight, x: 0.79, y: 0.78)
        Self.expectClose(region.bottomLeft, x: 0.13, y: 0.76)
    }

    @Test("out-of-range Vision values are clamped to [0,1]")
    func valuesAreClamped() {
        let region = CardRegion(
            visionTopLeft: CGPoint(x: -0.2, y: 1.3),
            visionTopRight: CGPoint(x: 1.4, y: 1.1),
            visionBottomRight: CGPoint(x: 1.2, y: -0.3),
            visionBottomLeft: CGPoint(x: -0.1, y: -0.2),
            sourcePixelWidth: 100,
            sourcePixelHeight: 100
        )

        // topLeft: x −0.2 → 0; y 1−1.3 = −0.3 → 0
        #expect(region.topLeft == NormalizedPoint(x: 0, y: 0))
        // topRight: x 1.4 → 1; y 1−1.1 = −0.1 → 0
        #expect(region.topRight == NormalizedPoint(x: 1, y: 0))
        // bottomRight: x 1.2 → 1; y 1−(−0.3) = 1.3 → 1
        #expect(region.bottomRight == NormalizedPoint(x: 1, y: 1))
        // bottomLeft: x −0.1 → 0; y 1−(−0.2) = 1.2 → 1
        #expect(region.bottomLeft == NormalizedPoint(x: 0, y: 1))
    }

    @Test("NormalizedPoint clamps direct construction")
    func normalizedPointClamps() {
        #expect(NormalizedPoint(x: -1, y: 2) == NormalizedPoint(x: 0, y: 1))
        #expect(NormalizedPoint(x: 0.5, y: 0.5) == NormalizedPoint(x: 0.5, y: 0.5))
    }
}
