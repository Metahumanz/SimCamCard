//
//  AspectFillCoordinateMapper.swift
//  SimCamCard
//
//  Pure coordinate mapping for the resizeAspectFill preview
//  (Week 3 Increment 4 — T06 detected boundary overlay).
//
//  The preview layer uses videoGravity = .resizeAspectFill: the source
//  frame is scaled to FILL the viewport and the overflow is cropped
//  equally on both sides. A naive `x = normalizedX * viewWidth` mapping
//  is therefore WRONG whenever source and viewport aspect ratios
//  differ. This mapper applies the fill scale and the centering crop
//  offset explicitly.
//
//  Pure functions only — no AVFoundation, no SwiftUI state. Fully
//  unit-tested with numeric assertions (not snapshot-only).
//

import CoreGraphics

nonisolated enum AspectFillCoordinateMapper {

    /// Maps a normalized top-left-origin point in source space to a
    /// point in destination (view) space under resizeAspectFill.
    static func point(
        _ normalized: NormalizedPoint,
        sourceWidth: Double,
        sourceHeight: Double,
        destinationWidth: Double,
        destinationHeight: Double
    ) -> CGPoint {
        let scale = max(
            destinationWidth / sourceWidth,
            destinationHeight / sourceHeight
        )
        let displayedWidth = sourceWidth * scale
        let displayedHeight = sourceHeight * scale
        let offsetX = (destinationWidth - displayedWidth) / 2
        let offsetY = (destinationHeight - displayedHeight) / 2
        return CGPoint(
            x: offsetX + normalized.x * displayedWidth,
            y: offsetY + normalized.y * displayedHeight
        )
    }

    /// Convenience overload for pixel-integral sizes.
    static func point(
        _ normalized: NormalizedPoint,
        sourcePixelWidth: Int,
        sourcePixelHeight: Int,
        destinationSize: CGSize
    ) -> CGPoint {
        point(
            normalized,
            sourceWidth: Double(sourcePixelWidth),
            sourceHeight: Double(sourcePixelHeight),
            destinationWidth: destinationSize.width,
            destinationHeight: destinationSize.height
        )
    }
}
