//
//  CropDraft.swift
//  SimCamCard
//
//  Editable crop state for P04 (Week 3 Increment 5).
//
//  The draft carries only Sendable values — never CGImage/CIImage/
//  UIImage (those stay inside the processing boundary or exist only as
//  View-layer rendering adapters). Orientation is stored as its raw
//  EXIF value (project-owned equivalent) so the draft has no dependency
//  on the Sendable status of the ImageIO orientation type.
//

import Foundation
import ImageIO

/// Identity of one draggable card corner. Order:
/// topLeft → topRight → bottomRight → bottomLeft (visual order around
/// the upright image).
nonisolated enum CardCorner: String, Sendable, Equatable, CaseIterable {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft

    /// Stable accessibility identifier suffix (P04).
    var handleIdentifier: String {
        switch self {
        case .topLeft: "scan-crop-handle-top-left"
        case .topRight: "scan-crop-handle-top-right"
        case .bottomRight: "scan-crop-handle-bottom-right"
        case .bottomLeft: "scan-crop-handle-bottom-left"
        }
    }
}

/// The editable boundary draft rendered by P04.
nonisolated struct CropDraft: Sendable, Equatable {

    /// Untouched original capture/import.
    let source: CapturedPhoto

    /// Resolved EXIF orientation of `source` (raw CGImagePropertyOrientation
    /// value; use `orientation`).
    let sourceOrientationRaw: UInt32

    /// ORIENTED pixel dimensions of the source (axes swapped for
    /// 90°/270° orientations) — the coordinate space the normalized
    /// `region` is expressed against.
    let sourcePixelWidth: Int
    let sourcePixelHeight: Int

    /// Current (always geometry-valid) boundary.
    var region: CardRegion

    init(
        source: CapturedPhoto,
        sourceOrientation: CGImagePropertyOrientation,
        sourcePixelWidth: Int,
        sourcePixelHeight: Int,
        region: CardRegion
    ) {
        self.source = source
        self.sourceOrientationRaw = sourceOrientation.rawValue
        self.sourcePixelWidth = sourcePixelWidth
        self.sourcePixelHeight = sourcePixelHeight
        self.region = region
    }

    /// Resolved orientation of the source bytes.
    var sourceOrientation: CGImagePropertyOrientation {
        CGImagePropertyOrientation(rawValue: sourceOrientationRaw) ?? .up
    }

    /// Returns a copy with one corner replaced. The new point is
    /// clamped to 0...1 by NormalizedPoint; geometry validity is the
    /// caller's contract (invalid candidates are ignored).
    func moving(_ corner: CardCorner, to point: NormalizedPoint) -> CropDraft {
        var copy = self
        switch corner {
        case .topLeft: copy.region = CardRegion(
            topLeft: point, topRight: region.topRight,
            bottomRight: region.bottomRight, bottomLeft: region.bottomLeft,
            sourcePixelWidth: region.sourcePixelWidth,
            sourcePixelHeight: region.sourcePixelHeight)
        case .topRight: copy.region = CardRegion(
            topLeft: region.topLeft, topRight: point,
            bottomRight: region.bottomRight, bottomLeft: region.bottomLeft,
            sourcePixelWidth: region.sourcePixelWidth,
            sourcePixelHeight: region.sourcePixelHeight)
        case .bottomRight: copy.region = CardRegion(
            topLeft: region.topLeft, topRight: region.topRight,
            bottomRight: point, bottomLeft: region.bottomLeft,
            sourcePixelWidth: region.sourcePixelWidth,
            sourcePixelHeight: region.sourcePixelHeight)
        case .bottomLeft: copy.region = CardRegion(
            topLeft: region.topLeft, topRight: region.topRight,
            bottomRight: region.bottomRight, bottomLeft: point,
            sourcePixelWidth: region.sourcePixelWidth,
            sourcePixelHeight: region.sourcePixelHeight)
        }
        return copy
    }
}

/// Result of the still-image preparation step: the editable draft plus
/// whether the initial region came from real detection (→ S04
/// autoDetected) or the implementation fallback (→ manualAdjusting).
nonisolated struct CropPreparation: Sendable, Equatable {
    let draft: CropDraft
    /// True when Vision found the initial region; false for the
    /// no-detection inset-rectangle fallback.
    let wasDetected: Bool
}
