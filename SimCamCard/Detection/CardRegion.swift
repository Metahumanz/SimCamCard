//
//  CardRegion.swift
//  SimCamCard
//
//  Detection pipeline value (Week 3 Increment 4 — T06 automatic live
//  boundary detection).
//
//  Project-owned detection result. The ViewModel/View NEVER see Vision
//  objects (VNRectangleObservation stays inside the detector); only
//  this Sendable value type crosses the concurrency boundary from the
//  detection queue to the MainActor.
//
//  Coordinate convention (project-wide, do NOT leak Vision's
//  lower-left origin):
//    origin: top-left
//    x: 0...1 left → right
//    y: 0...1 top  → bottom
//
//  `sourcePixelSize` preserves the ORIENTED source pixel dimensions so
//  the preview overlay can map normalized points through the
//  resizeAspectFill crop (source aspect ratio is required for an exact
//  mapping — a bare quadrilateral is not sufficient).
//

import CoreGraphics

/// Normalized point in the project convention: origin top-left,
/// x right, y down, both clamped to 0...1.
nonisolated struct NormalizedPoint: Sendable, Equatable {
    let x: Double
    let y: Double

    init(x: Double, y: Double) {
        self.x = min(max(x, 0), 1)
        self.y = min(max(y, 0), 1)
    }
}

/// One detected card quadrilateral in normalized top-left-origin
/// coordinates, plus the oriented pixel size of the source it was
/// detected in.
nonisolated struct CardRegion: Sendable, Equatable {
    let topLeft: NormalizedPoint
    let topRight: NormalizedPoint
    let bottomRight: NormalizedPoint
    let bottomLeft: NormalizedPoint

    /// Oriented source pixel dimensions at detection time (after any
    /// physical connection rotation). Required by the resizeAspectFill
    /// overlay mapping.
    let sourcePixelWidth: Int
    let sourcePixelHeight: Int

    init(
        topLeft: NormalizedPoint,
        topRight: NormalizedPoint,
        bottomRight: NormalizedPoint,
        bottomLeft: NormalizedPoint,
        sourcePixelWidth: Int,
        sourcePixelHeight: Int
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.sourcePixelWidth = sourcePixelWidth
        self.sourcePixelHeight = sourcePixelHeight
    }

    /// Conversion from a Vision rectangle observation. Vision reports
    /// corners in NORMALIZED LOWER-LEFT-ORIGIN coordinates for the
    /// image as oriented by the request; this project uses top-left
    /// origin. Conversion: appY = 1 − visionY, applied per corner.
    /// Corner labels (topLeft etc.) still refer to the same visual
    /// corners of the upright image — only the axis flips. All values
    /// are clamped to [0,1] by NormalizedPoint.
    init(
        visionTopLeft: CGPoint,
        visionTopRight: CGPoint,
        visionBottomRight: CGPoint,
        visionBottomLeft: CGPoint,
        sourcePixelWidth: Int,
        sourcePixelHeight: Int
    ) {
        self.init(
            topLeft: NormalizedPoint(x: visionTopLeft.x, y: 1 - visionTopLeft.y),
            topRight: NormalizedPoint(x: visionTopRight.x, y: 1 - visionTopRight.y),
            bottomRight: NormalizedPoint(x: visionBottomRight.x, y: 1 - visionBottomRight.y),
            bottomLeft: NormalizedPoint(x: visionBottomLeft.x, y: 1 - visionBottomLeft.y),
            sourcePixelWidth: sourcePixelWidth,
            sourcePixelHeight: sourcePixelHeight
        )
    }
}
