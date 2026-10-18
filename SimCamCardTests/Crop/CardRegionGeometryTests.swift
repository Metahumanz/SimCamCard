//
//  CardRegionGeometryTests.swift
//  SimCamCardTests
//
//  Unit tests for the P04 quadrilateral validity gate
//  (Week 3 Increment 5).
//
//  Contract under test:
//   - axis-aligned rectangle and perspective quad are valid
//   - zero-area / collapsed-edge / self-intersecting / sub-minimum
//     regions are invalid
//   - points supplied outside 0...1 are clamped by NormalizedPoint
//     BEFORE validation, so an overshoot drag lands on the edge
//     rather than poisoning the draft
//   - the no-detection fallback is an inset axis-aligned rectangle
//

import CoreGraphics
import Testing
@testable import SimCamCard

@Suite("CardRegionGeometry")
struct CardRegionGeometryTests {

    // MARK: - Valid regions

    @Test("axis-aligned inset rectangle is valid")
    func axisAlignedRectangleIsValid() {
        let region = Self.region(
            tl: (0.1, 0.15), tr: (0.9, 0.15),
            br: (0.9, 0.85), bl: (0.1, 0.85)
        )
        #expect(CardRegionGeometry.isValid(region))
        #expect(CardRegionGeometry.normalizedArea(region) > 0.5)
    }

    @Test("perspective quadrilateral is valid")
    func perspectiveQuadIsValid() {
        let region = Self.region(
            tl: (0.20, 0.22), tr: (0.86, 0.18),
            br: (0.80, 0.82), bl: (0.25, 0.88)
        )
        #expect(CardRegionGeometry.isValid(region))
    }

    @Test("full-frame quadrilateral is valid")
    func fullFrameQuadIsValid() {
        let region = Self.region(
            tl: (0, 0), tr: (1, 0),
            br: (1, 1), bl: (0, 1)
        )
        #expect(CardRegionGeometry.isValid(region))
        #expect(abs(CardRegionGeometry.normalizedArea(region) - 1) < 1e-9)
    }

    // MARK: - Invalid regions

    @Test("zero-area collapsed line is invalid")
    func zeroAreaLineIsInvalid() {
        // All corners on one horizontal line.
        let region = Self.region(
            tl: (0.2, 0.5), tr: (0.8, 0.5),
            br: (0.8, 0.5), bl: (0.2, 0.5)
        )
        #expect(!CardRegionGeometry.isValid(region))
        #expect(CardRegionGeometry.normalizedArea(region) == 0)
    }

    @Test("collapsed edge is invalid")
    func collapsedEdgeIsInvalid() {
        // topLeft == topRight: the top edge has zero length.
        let region = Self.region(
            tl: (0.2, 0.2), tr: (0.2, 0.2),
            br: (0.8, 0.8), bl: (0.2, 0.8)
        )
        #expect(!CardRegionGeometry.isValid(region))
    }

    @Test("self-intersecting bow-tie is invalid")
    func bowTieIsInvalid() {
        // TL and TR cross past each other: the polygon winds in two
        // different directions (consecutive cross products flip sign).
        let region = Self.region(
            tl: (0.8, 0.8), tr: (0.2, 0.2),
            br: (0.8, 0.2), bl: (0.2, 0.8)
        )
        #expect(!CardRegionGeometry.isValid(region))
    }

    @Test("tiny sub-minimum quadrilateral is invalid")
    func tinyRegionIsInvalid() {
        // A 0.02 x 0.02 central square → area 0.0004 < 0.01.
        let region = Self.region(
            tl: (0.49, 0.49), tr: (0.51, 0.49),
            br: (0.51, 0.51), bl: (0.49, 0.51)
        )
        #expect(!CardRegionGeometry.isValid(region))
    }

    @Test("three-collinear-points quadrilateral is invalid")
    func collinearCornersAreInvalid() {
        // TL, TR, BR on the same straight line.
        let region = Self.region(
            tl: (0.1, 0.2), tr: (0.5, 0.2),
            br: (0.9, 0.2), bl: (0.5, 0.9)
        )
        #expect(!CardRegionGeometry.isValid(region))
    }

    // MARK: - Clamp contract

    @Test("corner moved outside bounds is clamped before validation")
    func outOfBoundsCornerClampsToEdge() {
        // Overshooting the top/left edges clamps back to (0,0); the
        // clamped point still forms a valid convex quad with the other
        // inset corners.
        let region = CardRegion(
            topLeft: NormalizedPoint(x: -0.4, y: -0.2),
            topRight: NormalizedPoint(x: 0.9, y: 0.15),
            bottomRight: NormalizedPoint(x: 0.9, y: 0.85),
            bottomLeft: NormalizedPoint(x: 0.1, y: 0.85),
            sourcePixelWidth: 100,
            sourcePixelHeight: 100
        )
        #expect(region.topLeft.x == 0)
        #expect(region.topLeft.y == 0)
        #expect(CardRegionGeometry.isValid(region))
    }

    // MARK: - Fallback

    @Test("fallback region is an inset axis-aligned rectangle")
    func fallbackRegionMatchesInsetContract() {
        let inset = CardRegionGeometry.fallbackInset
        let region = CardRegionGeometry.fallbackRegion(pixelWidth: 600, pixelHeight: 380)

        #expect(abs(region.topLeft.x - inset) < 1e-12)
        #expect(abs(region.topLeft.y - inset) < 1e-12)
        #expect(abs(region.bottomRight.x - (1 - inset)) < 1e-12)
        #expect(abs(region.bottomRight.y - (1 - inset)) < 1e-12)
        #expect(region.sourcePixelWidth == 600)
        #expect(region.sourcePixelHeight == 380)
        #expect(CardRegionGeometry.isValid(region))
    }

    // MARK: - Auto-detection acceptance gate

    @Test("large valid region is acceptable for auto-detection")
    func largeValidRegionIsAcceptable() {
        let region = Self.region(
            tl: (0.1, 0.15), tr: (0.9, 0.15),
            br: (0.9, 0.85), bl: (0.1, 0.85)
        )
        #expect(CardRegionGeometry.isAcceptableAutoDetection(region))
    }

    @Test("geometrically valid but tiny region is NOT acceptable for auto-detection")
    func tinyValidRegionIsNotAcceptable() {
        // 0.15 x 0.15 central square → area 0.0225: valid (>= 0.01) but
        // below the 0.05 conservative auto-detection threshold.
        let region = Self.region(
            tl: (0.425, 0.425), tr: (0.575, 0.425),
            br: (0.575, 0.575), bl: (0.425, 0.575)
        )
        #expect(CardRegionGeometry.isValid(region))
        #expect(CardRegionGeometry.normalizedArea(region) >= CardRegionGeometry.minimumNormalizedArea)
        #expect(CardRegionGeometry.normalizedArea(region) < CardRegionGeometry.minimumDetectedArea)
        #expect(!CardRegionGeometry.isAcceptableAutoDetection(region))
    }

    @Test("invalid region is NOT acceptable for auto-detection even if large")
    func invalidLargeRegionIsNotAcceptable() {
        // Bow-tie with area > 0.05 but self-intersecting.
        let region = Self.region(
            tl: (0.8, 0.8), tr: (0.2, 0.2),
            br: (0.8, 0.2), bl: (0.2, 0.8)
        )
        #expect(!CardRegionGeometry.isValid(region))
        #expect(!CardRegionGeometry.isAcceptableAutoDetection(region))
    }

    // MARK: - Helpers

    private static func region(
        tl: (Double, Double),
        tr: (Double, Double),
        br: (Double, Double),
        bl: (Double, Double)
    ) -> CardRegion {
        CardRegion(
            topLeft: NormalizedPoint(x: tl.0, y: tl.1),
            topRight: NormalizedPoint(x: tr.0, y: tr.1),
            bottomRight: NormalizedPoint(x: br.0, y: br.1),
            bottomLeft: NormalizedPoint(x: bl.0, y: bl.1),
            sourcePixelWidth: 100,
            sourcePixelHeight: 100
        )
    }
}
