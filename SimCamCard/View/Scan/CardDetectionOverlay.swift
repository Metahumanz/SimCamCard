//
//  CardDetectionOverlay.swift
//  SimCamCard
//
//  Detected-card boundary overlay (Week 3 Increment 4 — T06 detected
//  boundary presentation).
//
//  PRESENTATION ONLY. Input: one CardRegion + the container size it
//  must be mapped into. Output: a stroked quadrilateral Path. No
//  Vision, no detection-state mutation, no capture/crop, no stored
//  observation.
//
//  Visual contract from REF-scanner-02-card-detected.png (verified on
//  this machine): a thin bright cyan-blue stroke following the
//  detected quadrilateral; no corner handles, no fill, no glow, no
//  scanning animation, no confidence label. When no card is detected
//  the overlay is absent (the caller simply does not render it).
//
//  Mapping: the preview is resizeAspectFill, so normalized points are
//  mapped through AspectFillCoordinateMapper with the region's
//  oriented source pixel size — never a naive width/height scale.
//

import SwiftUI

struct CardDetectionOverlay: View {

    let region: CardRegion
    let containerSize: CGSize

    /// Bright cyan-blue stroke measured from
    /// REF-scanner-02-card-detected.png.
    private static let strokeColor = Color(red: 0.0, green: 0.62, blue: 1.0)
    private static let strokeWidth: CGFloat = 2

    var body: some View {
        Path { path in
            let corners = [
                region.topLeft, region.topRight,
                region.bottomRight, region.bottomLeft,
            ].map {
                AspectFillCoordinateMapper.point(
                    $0,
                    sourcePixelWidth: region.sourcePixelWidth,
                    sourcePixelHeight: region.sourcePixelHeight,
                    destinationSize: containerSize
                )
            }
            path.addLines(corners)
            path.closeSubpath()
        }
        .stroke(Self.strokeColor, lineWidth: Self.strokeWidth)
        .frame(width: containerSize.width, height: containerSize.height)
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityIdentifier("scan-card-detected-overlay")
    }
}
