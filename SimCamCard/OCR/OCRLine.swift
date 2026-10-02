//
//  OCRLine.swift
//  SimCamCard
//
//  Raw OCR line value (Week 3 Increment 6 — T07 raw text).
//
//  This is the RAW recognition output only: no field classification
//  (name / company / title / phone / email), no regex, no parser, no
//  normalization. Week 4 structured extraction consumes the preserved
//  `CardOCRResult.rawText`.
//

import Foundation

/// One preserved raw Vision text observation (T07).
nonisolated struct OCRLine: Sendable, Equatable {

    /// The top-1 candidate string with ONLY leading/trailing
    /// whitespace and newlines removed. Interior characters — spaces,
    /// punctuation, digits, letter case, CJK — are preserved verbatim:
    /// no phone normalization, no email lowercasing, no de-duplication.
    let text: String

    /// Vision top-1 candidate confidence in [0, 1]. Metadata only; it
    /// is never used to filter or reorder lines in T07.
    let confidence: Float

    init(text: String, confidence: Float) {
        self.text = text
        self.confidence = confidence
    }
}

/// Failure while running raw text recognition (S05 implementation
/// transient `.failed`). Distinct from `CropError` — the still pipeline
/// has already produced its upright PNG before OCR begins.
nonisolated enum OCRError: Error, Equatable, Sendable {
    /// The Vision text-recognition request could not execute on the
    /// processed image data. A request that runs and returns ZERO
    /// observations is NOT an error — an empty raw result is a valid
    /// outcome (`RecognitionState.emptyRawResult`).
    case recognitionFailed
}
