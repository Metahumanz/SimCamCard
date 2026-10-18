//
//  CardRegionGeometry.swift
//  SimCamCard
//
//  Pure quadrilateral geometry for P04 manual adjustment
//  (Week 3 Increment 5).
//
//  A normalized [0,1] clamp alone is not enough: four in-bounds points
//  can still form a self-intersecting "bow-tie", a zero-area segment
//  or a collapsed edge. The crop draft must ALWAYS hold a usable
//  convex quadrilateral, so invalid drag candidates are rejected
//  before they are applied (confirm is never the first validity gate).
//
//  Pure functions only — no UIKit, no Core Image.
//

import CoreGraphics

nonisolated enum CardRegionGeometry {

    /// Minimum normalized (unit-square) polygon area for a geometrically
    /// valid region. Centralized — no magic numbers at call sites.
    static let minimumNormalizedArea: Double = 0.01

    /// Conservative threshold for auto-accepting a Vision-detected
    /// rectangle in the still-image pipeline. Derived from the 34-card
    /// dataset: correct crops occupy 0.47–0.93 of the frame; erroneous
    /// lock-on quads (tiny decorative rectangles) occupy 0.007–0.024.
    /// 0.05 cleanly separates the two populations with a >10× margin
    /// over the bad-quad ceiling. Regions below this are NOT invalid
    /// geometry — they are rejected from auto-acceptance and routed to
    /// the manual-adjust fallback (`wasDetected == false`).
    static let minimumDetectedArea: Double = 0.05

    /// Inset fraction used by the no-detection fallback rectangle
    /// (implementation robustness, not Reference-observed behavior):
    /// 6% on every edge.
    static let fallbackInset: Double = 0.06

    /// Edges shorter than this normalized length count as collapsed.
    private static let minimumEdgeLength: Double = 1e-4

    /// Cross products smaller than this are treated as zero
    /// (collinear corners — a collapsed/ambiguous quadrilateral).
    private static let crossEpsilon: Double = 1e-6

    /// True iff the region is a usable convex quadrilateral:
    /// corners in preserved order, every edge non-degenerate, all
    /// consecutive cross products the same sign (no corner crossing /
    /// self-intersection), and shoelace area at least
    /// `minimumNormalizedArea`. All corners are in 0...1 by
    /// NormalizedPoint's own clamp contract.
    static func isValid(_ region: CardRegion) -> Bool {
        let corners = [
            region.topLeft, region.topRight,
            region.bottomRight, region.bottomLeft
        ]
        let points = corners.map { CGPoint(x: $0.x, y: $0.y) }

        for index in 0..<4 {
            let a = points[index]
            let b = points[(index + 1) % 4]
            let edge = CGPoint(x: b.x - a.x, y: b.y - a.y)
            guard hypot(edge.x, edge.y) >= minimumEdgeLength else { return false }
        }

        let area = abs(shoelaceArea(points))
        guard area / 2 >= minimumNormalizedArea else { return false }

        var sign = 0
        for index in 0..<4 {
            let a = points[index]
            let b = points[(index + 1) % 4]
            let c = points[(index + 2) % 4]
            let cross =
                (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x)
            if abs(cross) < crossEpsilon { return false } // collinear
            let thisSign = cross > 0 ? 1 : -1
            if sign == 0 {
                sign = thisSign
            } else if sign != thisSign {
                return false // mixed signs → self-intersection
            }
        }
        return true
    }

    /// True iff the region is geometrically valid AND large enough to
    /// auto-accept in the still-image pipeline. This is a conservative
    /// rejection for tiny-area quads, not a relaxation of validity.
    static func isAcceptableAutoDetection(_ region: CardRegion) -> Bool {
        isValid(region) && normalizedArea(region) >= minimumDetectedArea
    }

    /// Signed shoelace area (absolute value / 2 is the polygon area)
    /// in the normalized unit square.
    static func normalizedArea(_ region: CardRegion) -> Double {
        let points = [region.topLeft, region.topRight,
                      region.bottomRight, region.bottomLeft]
            .map { CGPoint(x: $0.x, y: $0.y) }
        return abs(shoelaceArea(points)) / 2
    }

    /// Implementation fallback when still-image detection finds no
    /// rectangle: an axis-aligned inset rectangle so manual cropping is
    /// still possible. NOT Reference-observed behavior.
    static func fallbackRegion(pixelWidth: Int, pixelHeight: Int) -> CardRegion {
        let inset = fallbackInset
        return CardRegion(
            topLeft: NormalizedPoint(x: inset, y: inset),
            topRight: NormalizedPoint(x: 1 - inset, y: inset),
            bottomRight: NormalizedPoint(x: 1 - inset, y: 1 - inset),
            bottomLeft: NormalizedPoint(x: inset, y: 1 - inset),
            sourcePixelWidth: pixelWidth,
            sourcePixelHeight: pixelHeight
        )
    }

    private static func shoelaceArea(_ points: [CGPoint]) -> Double {
        var sum = 0.0
        for index in 0..<points.count {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            sum += a.x * b.y - b.x * a.y
        }
        return sum
    }
}
