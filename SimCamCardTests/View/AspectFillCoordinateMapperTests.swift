//
//  AspectFillCoordinateMapperTests.swift
//  SimCamCardTests
//
//  Numeric unit tests for the resizeAspectFill coordinate mapper
//  (Week 3 Increment 4). Assertions are numeric, not snapshot-based.
//
//  Mapping contract:
//    scale = max(destW/srcW, destH/srcH)
//    displayed = source * scale   (overflow cropped equally both sides)
//    offset  = (dest − displayed) / 2
//    screen  = offset + normalized * displayed
//

import CoreGraphics
import Testing
@testable import SimCamCard

@Suite("AspectFillCoordinateMapper")
struct AspectFillCoordinateMapperTests {

    private func map(
        _ x: Double, _ y: Double,
        sourceW: Double, sourceH: Double,
        destW: Double, destH: Double
    ) -> CGPoint {
        AspectFillCoordinateMapper.point(
            NormalizedPoint(x: x, y: y),
            sourceWidth: sourceW, sourceHeight: sourceH,
            destinationWidth: destW, destinationHeight: destH
        )
    }

    // MARK: - same aspect ratio

    @Test("same aspect: no crop, linear scale")
    func sameAspectNoCrop() {
        // 1:1 source into 1:1 destination, 2× scale.
        #expect(map(0, 0, sourceW: 100, sourceH: 100, destW: 200, destH: 200) == CGPoint(x: 0, y: 0))
        #expect(map(1, 1, sourceW: 100, sourceH: 100, destW: 200, destH: 200) == CGPoint(x: 200, y: 200))
        #expect(map(0.5, 0.25, sourceW: 100, sourceH: 100, destW: 200, destH: 200) == CGPoint(x: 100, y: 50))
    }

    // MARK: - source wider than destination

    @Test("4:3 source in tall viewport: width matches, height overflows (top/bottom crop)")
    func widerSourceCropsTopBottom() {
        // Source 400×300 (4:3) into destination 300×600 (1:2).
        // scale = max(300/400, 600/300) = max(0.75, 2) = 2
        // displayed = 800×600 → offsetX = (300−800)/2 = −250, offsetY = 0
        let p00 = map(0, 0, sourceW: 400, sourceH: 300, destW: 300, destH: 600)
        #expect(p00 == CGPoint(x: -250, y: 0))
        let p11 = map(1, 1, sourceW: 400, sourceH: 300, destW: 300, destH: 600)
        #expect(p11 == CGPoint(x: 550, y: 600))
        // Center of the source maps to the center of the destination.
        let pCenter = map(0.5, 0.5, sourceW: 400, sourceH: 300, destW: 300, destH: 600)
        #expect(pCenter == CGPoint(x: 150, y: 300))
    }

    // MARK: - source taller than destination

    @Test("portrait source in landscape destination: height matches, width overflows (left/right crop)")
    func tallerSourceCropsLeftRight() {
        // Source 300×600 into destination 600×300.
        // scale = max(600/300, 300/600) = max(2, 0.5) = 2
        // displayed = 600×1200 → offsetX = 0, offsetY = (300−1200)/2 = −450
        let p00 = map(0, 0, sourceW: 300, sourceH: 600, destW: 600, destH: 300)
        #expect(p00 == CGPoint(x: 0, y: -450))
        let p11 = map(1, 1, sourceW: 300, sourceH: 600, destW: 600, destH: 300)
        #expect(p11 == CGPoint(x: 600, y: 750))
        let pCenter = map(0.5, 0.5, sourceW: 300, sourceH: 600, destW: 600, destH: 300)
        #expect(pCenter == CGPoint(x: 300, y: 150))
    }

    // MARK: - all four quadrilateral corners

    @Test("all four corners map consistently (camera-like 1920×1080 source into phone viewport)")
    func allFourCorners() {
        // Source 1920×1080 (16:9) into destination 390×700 (tall).
        // scale = max(390/1920, 700/1080) = max(0.203125, 0.6481…) = 0.648148…
        // displayed = 1920×s = 1244.444… × 1080×s = 700
        // offsetX = (390 − 1244.444…)/2 = −427.222…, offsetY = 0
        let s = 700.0 / 1080.0
        let displayedW = 1920.0 * s
        let offsetX = (390.0 - displayedW) / 2

        let tl = map(0.22, 0.30, sourceW: 1920, sourceH: 1080, destW: 390, destH: 700)
        let tr = map(0.78, 0.30, sourceW: 1920, sourceH: 1080, destW: 390, destH: 700)
        let br = map(0.78, 0.72, sourceW: 1920, sourceH: 1080, destW: 390, destH: 700)
        let bl = map(0.22, 0.72, sourceW: 1920, sourceH: 1080, destW: 390, destH: 700)

        #expect(abs(tl.x - (offsetX + 0.22 * displayedW)) < 0.001)
        #expect(abs(tl.y - (0.30 * 700)) < 0.001)
        #expect(abs(tr.x - (offsetX + 0.78 * displayedW)) < 0.001)
        #expect(tr.y == tl.y)
        #expect(abs(br.x - tr.x) < 0.001)
        #expect(abs(br.y - (0.72 * 700)) < 0.001)
        #expect(bl.x == tl.x)
        #expect(bl.y == br.y)
    }
}
