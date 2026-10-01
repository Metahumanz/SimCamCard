//
//  AspectFitCoordinateMapperTests.swift
//  SimCamCardTests
//
//  Unit tests for the P04 resizeAspectFit coordinate mapper
//  (Week 3 Increment 5).
//
//  Contract under test:
//   - same aspect: image fills the container, no letterbox
//   - wide source / tall container: side letterbox offsets
//   - tall source / wide container: top/bottom letterbox offsets
//   - forward → inverse round trip
//   - inverse drag points outside the displayed image clamp to 0...1
//

import CoreGraphics
import Testing
@testable import SimCamCard

@Suite("AspectFitCoordinateMapper")
struct AspectFitCoordinateMapperTests {

    private static let accuracy = 1e-9

    // MARK: - Layout

    @Test("same-aspect source fills the container without letterbox")
    func sameAspectLayoutFillsContainer() {
        let layout = AspectFitCoordinateMapper.layout(
            sourceWidth: 100, sourceHeight: 100,
            containerWidth: 200, containerHeight: 200
        )
        #expect(abs(layout.scale - 2) < Self.accuracy)
        #expect(abs(layout.displayWidth - 200) < Self.accuracy)
        #expect(abs(layout.displayHeight - 200) < Self.accuracy)
        #expect(layout.offsetX == 0)
        #expect(layout.offsetY == 0)
    }

    @Test("wide source in tall container is side-letterboxed")
    func wideSourceInTallContainer() {
        // 200x100 image in 100x200 container → scale 0.5 → 100x50,
        // 75 points of vertical letterbox on each side.
        let layout = AspectFitCoordinateMapper.layout(
            sourceWidth: 200, sourceHeight: 100,
            containerWidth: 100, containerHeight: 200
        )
        #expect(abs(layout.scale - 0.5) < Self.accuracy)
        #expect(abs(layout.displayWidth - 100) < Self.accuracy)
        #expect(abs(layout.displayHeight - 50) < Self.accuracy)
        #expect(layout.offsetX == 0)
        #expect(abs(layout.offsetY - 75) < Self.accuracy)
    }

    @Test("tall source in wide container is vertically letterboxed")
    func tallSourceInWideContainer() {
        // 100x200 image in 200x100 container → scale 0.5 → 50x100,
        // 75 points of horizontal letterbox on each side.
        let layout = AspectFitCoordinateMapper.layout(
            sourceWidth: 100, sourceHeight: 200,
            containerWidth: 200, containerHeight: 100
        )
        #expect(abs(layout.scale - 0.5) < Self.accuracy)
        #expect(abs(layout.displayWidth - 50) < Self.accuracy)
        #expect(abs(layout.displayHeight - 100) < Self.accuracy)
        #expect(abs(layout.offsetX - 75) < Self.accuracy)
        #expect(layout.offsetY == 0)
    }

    // MARK: - Forward mapping

    @Test("normalized corners map to the fitted image corners")
    func forwardCornersMapToDisplayedEdges() {
        let topLeft = AspectFitCoordinateMapper.point(
            NormalizedPoint(x: 0, y: 0),
            sourceWidth: 200, sourceHeight: 100,
            containerWidth: 100, containerHeight: 200
        )
        #expect(abs(topLeft.x - 0) < Self.accuracy)
        #expect(abs(topLeft.y - 75) < Self.accuracy)

        let bottomRight = AspectFitCoordinateMapper.point(
            NormalizedPoint(x: 1, y: 1),
            sourceWidth: 200, sourceHeight: 100,
            containerWidth: 100, containerHeight: 200
        )
        #expect(abs(bottomRight.x - 100) < Self.accuracy)
        #expect(abs(bottomRight.y - 125) < Self.accuracy)
    }

    // MARK: - Round trip

    @Test("forward then inverse restores the normalized point")
    func forwardInverseRoundTrip() {
        let original = NormalizedPoint(x: 0.3, y: 0.7)
        let viewPoint = AspectFitCoordinateMapper.point(
            original,
            sourceWidth: 320, sourceHeight: 480,
            containerWidth: 390, containerHeight: 844
        )
        let restored = AspectFitCoordinateMapper.normalized(
            viewX: Double(viewPoint.x), viewY: Double(viewPoint.y),
            sourceWidth: 320, sourceHeight: 480,
            containerWidth: 390, containerHeight: 844
        )
        #expect(abs(restored.x - original.x) < Self.accuracy)
        #expect(abs(restored.y - original.y) < Self.accuracy)
    }

    // MARK: - Clamp

    @Test("drag inside the letterbox clamps to the nearest edge")
    func dragOutsideDisplayedImageClamps() {
        // Wide source in tall container (display 100x50 at y 75...125):
        // a view point in the top letterbox and past the left edge
        // maps to normalized (0, 0).
        let clamped = AspectFitCoordinateMapper.normalized(
            viewX: -40, viewY: 10,
            sourceWidth: 200, sourceHeight: 100,
            containerWidth: 100, containerHeight: 200
        )
        #expect(clamped.x == 0)
        #expect(clamped.y == 0)

        // Bottom-right letterbox corner maps to (1, 1).
        let farCorner = AspectFitCoordinateMapper.normalized(
            viewX: 500, viewY: 900,
            sourceWidth: 200, sourceHeight: 100,
            containerWidth: 100, containerHeight: 200
        )
        #expect(farCorner.x == 1)
        #expect(farCorner.y == 1)
    }
}
