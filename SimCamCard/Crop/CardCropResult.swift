//
//  CardCropResult.swift
//  SimCamCard
//
//  Crop pipeline transport value (Week 3 Increment 5 — P04 confirm +
//  perspective correction).
//
//  Contract:
//    original raw image (CapturedPhoto, bytes NEVER overwritten)
//    + confirmed boundary (CardRegion)
//    + perspective-corrected image (new upright PNG Data)
//
//  This is a PIPELINE TRANSPORT VALUE, not a Domain Model: no OCR text,
//  no structured fields, no BusinessCard ID, no tags/notes. The next
//  increment (OCR) consumes `processedImageData`.
//

import Foundation

/// Failure while preparing or correcting a still image (S04
/// implementation transient `.failed`). Distinct from
/// `CameraSessionError` — the camera is not involved here.
nonisolated enum CropError: Error, Equatable, Sendable {
    /// The raw bytes could not be decoded as an image (ImageIO could
    /// not produce a primary CGImage). Stable failure — never a crash.
    case invalidImageData
    /// The candidate quadrilateral is not a usable convex region
    /// (self-intersection / collapse / below minimum area).
    case invalidRegion
    /// The Core Image perspective filter/render/PNG-encode pipeline
    /// produced no usable output.
    case correctionFailed
}

/// The stable result of confirming P04: the untouched original, the
/// boundary the user confirmed, and the new perspective-corrected,
/// physically upright PNG.
nonisolated struct CardCropResult: Sendable, Equatable {

    /// The original capture/import. Raw bytes are preserved unchanged;
    /// correction always produces a SECOND copy of data.
    let original: CapturedPhoto

    /// Final boundary (automatic initial region or manually adjusted).
    let confirmedRegion: CardRegion

    /// New lossless, deterministic, physically upright
    /// perspective-corrected PNG bytes (orientation semantics `.up`;
    /// no non-up EXIF orientation is written).
    let processedImageData: Data

    /// Pixel dimensions of the processed PNG (must be > 0).
    let processedPixelWidth: Int
    let processedPixelHeight: Int

    init(
        original: CapturedPhoto,
        confirmedRegion: CardRegion,
        processedImageData: Data,
        processedPixelWidth: Int,
        processedPixelHeight: Int
    ) {
        self.original = original
        self.confirmedRegion = confirmedRegion
        self.processedImageData = processedImageData
        self.processedPixelWidth = processedPixelWidth
        self.processedPixelHeight = processedPixelHeight
    }
}
