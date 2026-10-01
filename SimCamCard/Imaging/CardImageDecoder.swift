//
//  CardImageDecoder.swift
//  SimCamCard
//
//  Still-image decode helper for the shared camera/import crop
//  pipeline (Week 3 Increment 5).
//
//  Contract:
//    raw Data → CGImageSource → primary CGImage + resolved
//    CGImagePropertyOrientation + ORIENTED pixel dimensions.
//
//  UIImage is deliberately NOT the processing source of truth — it
//  exists only as a View-layer rendering adapter. Decoding uses ImageIO
//  directly; the bytes themselves are never modified.
//

import Foundation
import ImageIO
import CoreGraphics

/// One decoded still image plus the orientation semantics needed to
/// make it upright.
nonisolated struct DecodedImage: Sendable {
    /// Primary image from the source data.
    let cgImage: CGImage
    /// Resolved EXIF orientation (`.up` when metadata absent).
    let orientation: CGImagePropertyOrientation
    /// Pixel dimensions AFTER applying `orientation` (axes swap for
    /// 90°/270° orientations).
    let orientedPixelWidth: Int
    let orientedPixelHeight: Int
}

nonisolated enum CardImageDecoder {

    /// Decodes the primary image in `data`. Throws
    /// `CropError.invalidImageData` on any unreadable/empty input —
    /// never crashes.
    static func decode(_ data: Data) throws -> DecodedImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw CropError.invalidImageData
        }

        let orientation = ImageOrientationResolver.orientation(of: data)
        let swapsAxes: Bool = switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored: true
        default: false
        }
        let orientedWidth = swapsAxes ? cgImage.height : cgImage.width
        let orientedHeight = swapsAxes ? cgImage.width : cgImage.height

        return DecodedImage(
            cgImage: cgImage,
            orientation: orientation,
            orientedPixelWidth: orientedWidth,
            orientedPixelHeight: orientedHeight
        )
    }
}
