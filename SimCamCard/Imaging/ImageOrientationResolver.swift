//
//  ImageOrientationResolver.swift
//  SimCamCard
//
//  Orientation pipeline helper (Week 3 Increment 4).
//
//  Contract: raw image bytes → ImageIO metadata → the
//  CGImagePropertyOrientation a downstream Vision request must use to
//  interpret those bytes.
//
//  This resolver NEVER modifies the image bytes: no UIImage
//  normalization, no EXIF stripping, no JPEG re-encode, no PNG
//  conversion. `CapturedPhoto.data` stays byte-identical; orientation
//  is carried as semantics alongside it.
//
//  Defaults: missing orientation metadata → .up; unreadable/invalid
//  image data → .up (defined default contract, recorded in
//  ai/changes.md).
//

import Foundation
import ImageIO

nonisolated enum ImageOrientationResolver {

    /// Reads the EXIF/TIFF orientation of the first image in `data`.
    /// Returns `.up` when no orientation metadata is present or the
    /// data is not a readable image.
    static func orientation(of data: Data) -> CGImagePropertyOrientation {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let rawValue = properties[kCGImagePropertyOrientation] as? UInt32,
              let orientation = CGImagePropertyOrientation(rawValue: rawValue)
        else {
            return .up
        }
        return orientation
    }
}
