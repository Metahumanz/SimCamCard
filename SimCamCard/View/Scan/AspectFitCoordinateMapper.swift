//
//  AspectFitCoordinateMapper.swift
//  SimCamCard
//
//  Pure coordinate mapping for the P04 crop page
//  (Week 3 Increment 5).
//
//  P04 must show the WHOLE image (resizeAspectFit), so the Scanner's
//  AspectFill math must NOT be reused: fit scales to CONTAIN the image
//  and letterboxes the unused axis. This mapper provides:
//   - forward:  normalized image point → view point
//   - inverse:  view drag point     → normalized image point
//  The inverse subtracts the letterbox offset and clamps to 0...1, so
//  a drag that ends outside the displayed image maps to the nearest
//  edge rather than an out-of-range corner.
//
//  Pure functions only — no AVFoundation, no SwiftUI state.
//

import CoreGraphics

nonisolated enum AspectFitCoordinateMapper {

    /// The fitted placement of a source rect inside a container.
    struct Layout: Equatable {
        let scale: Double
        let displayWidth: Double
        let displayHeight: Double
        let offsetX: Double
        let offsetY: Double
    }

    /// scale = min(cw/sw, ch/sh); the image is centered, so the
    /// letterbox gap is split equally on the fitting axis.
    static func layout(
        sourceWidth: Double,
        sourceHeight: Double,
        containerWidth: Double,
        containerHeight: Double
    ) -> Layout {
        precondition(sourceWidth > 0 && sourceHeight > 0
                     && containerWidth > 0 && containerHeight > 0)
        let scale = min(
            containerWidth / sourceWidth,
            containerHeight / sourceHeight
        )
        let displayWidth = sourceWidth * scale
        let displayHeight = sourceHeight * scale
        return Layout(
            scale: scale,
            displayWidth: displayWidth,
            displayHeight: displayHeight,
            offsetX: (containerWidth - displayWidth) / 2,
            offsetY: (containerHeight - displayHeight) / 2
        )
    }

    /// Forward: normalized image point → view point.
    static func point(
        _ normalized: NormalizedPoint,
        sourceWidth: Double,
        sourceHeight: Double,
        containerWidth: Double,
        containerHeight: Double
    ) -> CGPoint {
        let layout = layout(
            sourceWidth: sourceWidth,
            sourceHeight: sourceHeight,
            containerWidth: containerWidth,
            containerHeight: containerHeight
        )
        return CGPoint(
            x: layout.offsetX + normalized.x * layout.displayWidth,
            y: layout.offsetY + normalized.y * layout.displayHeight
        )
    }

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
            containerWidth: Double(destinationSize.width),
            containerHeight: Double(destinationSize.height)
        )
    }

    /// Inverse: view point → normalized image point (letterbox offset
    /// removed; result clamped to 0...1).
    static func normalized(
        viewX: Double,
        viewY: Double,
        sourceWidth: Double,
        sourceHeight: Double,
        containerWidth: Double,
        containerHeight: Double
    ) -> NormalizedPoint {
        let layout = self.layout(
            sourceWidth: sourceWidth,
            sourceHeight: sourceHeight,
            containerWidth: containerWidth,
            containerHeight: containerHeight
        )
        let normalizedX = (viewX - layout.offsetX) / layout.displayWidth
        let normalizedY = (viewY - layout.offsetY) / layout.displayHeight
        return NormalizedPoint(x: normalizedX, y: normalizedY)
    }

    static func normalized(
        viewPoint: CGPoint,
        sourcePixelWidth: Int,
        sourcePixelHeight: Int,
        containerSize: CGSize
    ) -> NormalizedPoint {
        normalized(
            viewX: Double(viewPoint.x),
            viewY: Double(viewPoint.y),
            sourceWidth: Double(sourcePixelWidth),
            sourceHeight: Double(sourcePixelHeight),
            containerWidth: Double(containerSize.width),
            containerHeight: Double(containerSize.height)
        )
    }
}
