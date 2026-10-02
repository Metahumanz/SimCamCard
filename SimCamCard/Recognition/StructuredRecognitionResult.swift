
//  StructuredRecognitionResult.swift
//  SimCamCard
//
//  Week 4 Increment 1 — structured extraction pipeline intermediate.
//
//  Frozen pipeline (spec/data-model.md §OCR Pipeline Data):
//
//    Original image
//    → Processed image (CardCropResult)
//    → Raw OCR (CardOCRResult: [OCRLine] + rawText)
//    → Structured extraction (THIS value)
//    → User-corrected final record (later increment)
//
//  The extractor never mutates, replaces or regenerates the carried
//  CardOCRResult (and therefore never touches rawText / raw lines).
//  Full traceability chain:
//
//    StructuredRecognitionResult
//    → CardOCRResult
//      → CardCropResult (original CapturedPhoto + processed image)
//      → [OCRLine] + rawText
//
//  This is NOT a BusinessCard: there is deliberately no save /
//  repository integration in this increment.
//

import Foundation

nonisolated struct StructuredRecognitionResult: Sendable, Equatable {

    /// The preserved raw OCR result these fields were derived from.
    /// Reference equality by value; rawText is never rewritten.
    let ocrResult: CardOCRResult

    /// Deterministically classified structured fields.
    var fields: StructuredCardFields

    init(ocrResult: CardOCRResult, fields: StructuredCardFields) {
        self.ocrResult = ocrResult
        self.fields = fields
    }
}
