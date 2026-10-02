//
//  CardOCRResult.swift
//  SimCamCard
//
//  Raw OCR pipeline transport value (Week 3 Increment 6 — T07).
//
//  Contract:
//    CardCropResult (upright PNG)
//    + raw observations preserved as [OCRLine]
//    + rawText (newline-joined, generated once, never rewritten)
//
//  This is a PIPELINE TRANSPORT VALUE, not a Domain Model: no
//  structured fields, no BusinessCard identity, no tags/notes, no
//  Repository persistence. Week 4 extraction consumes `rawText`.
//

import Foundation

nonisolated struct CardOCRResult: Sendable, Equatable {

    /// The crop result whose `processedImageData` was recognized.
    /// Carried so the transitional recognition screen can display the
    /// upright image and later extraction can trace its source.
    let cropResult: CardCropResult

    /// Raw lines in EXACTLY Vision's observation order. Each line
    /// keeps its top-1 candidate verbatim (only surrounding whitespace
    /// trimmed). Never reordered, filtered by confidence, merged or
    /// deduplicated in T07.
    let lines: [OCRLine]

    /// `lines.map(\.text)` joined with "\n". Generated once at
    /// construction and never mutated afterward — the single
    /// preserved source of truth that Week 4 extraction consumes.
    /// Empty when Vision returned no usable text.
    let rawText: String

    init(cropResult: CardCropResult, lines: [OCRLine]) {
        self.cropResult = cropResult
        self.lines = lines
        self.rawText = lines.map(\.text).joined(separator: "\n")
    }
}
