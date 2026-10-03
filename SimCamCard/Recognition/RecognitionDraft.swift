//
//  RecognitionDraft.swift
//  SimCamCard
//
//  Week 4 Increment 3 — T11 manual correction intermediate.
//
//  The user-editable buffer that sits BETWEEN the immutable
//  structured extraction result and (a later increment) the final
//  BusinessCard. Three layers stay deliberately separated:
//
//    1. Raw OCR            — StructuredRecognitionResult.ocrResult
//                            (CardOCRResult.lines + rawText), never
//                            rewritten (spec/data-model.md §OCR
//                            Pipeline Data).
//    2. Structured result  — StructuredRecognitionResult.fields, the
//                            deterministic extractor output, never
//                            mutated.
//    3. Corrected draft    — THIS value: mutable String fields the
//                            user can edit in P05 manualEditing.
//
//  Traceability chain is always available:
//
//    draft → source (StructuredRecognitionResult)
//          → ocrResult.rawText / OCRLine[]
//          → ocrResult.cropResult (original + processed image)
//
//  This is a PIPELINE INTERMEDIATE, not the frozen BusinessCard
//  entity: no persistence, no Repository involvement, no final
//  identity materialization in this increment. PhoneField.id is an
//  edit-UI row identity only; sourceID preserves the structured
//  intermediate PhoneNumber.id; persisted domain identity is
//  reprocessed when a later increment materializes the final record.
//

import Foundation

nonisolated struct RecognitionDraft: Sendable, Equatable {

    /// Editable phone row. `id` is the stable edit-UI row identity
    /// (array position at draft creation); `sourceID` preserves the
    /// structured intermediate PhoneNumber.id. Kind is NOT editable
    /// in this increment — correction covers recognized values only.
    nonisolated struct PhoneField: Identifiable, Sendable, Equatable {
        let id: Int
        let sourceID: UUID
        let kind: PhoneNumber.Kind
        var value: String
    }

    /// Editable email row. `id` is the stable edit-UI row identity
    /// (array position at draft creation).
    nonisolated struct EmailField: Identifiable, Sendable, Equatable {
        let id: Int
        var value: String
    }

    /// The immutable structured result this draft was created from.
    /// Never mutated: both the original structured fields and the
    /// raw OCR chain remain reachable through it.
    let source: StructuredRecognitionResult

    var name: String
    var company: String
    var jobTitle: String

    var phones: [PhoneField]
    var emails: [EmailField]

    var website: String
    var address: String

    init(source: StructuredRecognitionResult) {
        self.source = source
        let fields = source.fields
        self.name = fields.name ?? ""
        self.company = fields.company ?? ""
        self.jobTitle = fields.jobTitle ?? ""
        self.phones = fields.phones.enumerated().map { index, phone in
            PhoneField(id: index, sourceID: phone.id, kind: phone.kind, value: phone.value)
        }
        self.emails = fields.emails.enumerated().map { index, value in
            EmailField(id: index, value: value)
        }
        self.website = fields.website ?? ""
        self.address = fields.address ?? ""
    }

    // MARK: - Corrected projection

    /// Projects the edited strings back into a StructuredCardFields
    /// value suitable for the later materialization step.
    ///
    /// Blank normalization: surrounding whitespace/newlines are
    /// trimmed; a resulting empty string becomes nil (scalars) or is
    /// dropped from the collection (phones/emails). Non-empty content
    /// is preserved verbatim apart from the surrounding trim — no
    /// semantic correction (no phone reformatting, no email
    /// lower-casing, no value repair).
    ///
    /// Phone kind is preserved from extraction. The projected phone
    /// keeps its sourceID as its intermediate identity; final
    /// persisted identity is assigned in the later Save increment.
    ///
    /// `unclassifiedText` is not user-editable here and is carried
    /// through unchanged so no preserved evidence is lost.
    var correctedFields: StructuredCardFields {
        StructuredCardFields(
            name: Self.normalized(name),
            company: Self.normalized(company),
            jobTitle: Self.normalized(jobTitle),
            phones: phones.compactMap { phone in
                guard let value = Self.normalized(phone.value) else { return nil }
                return PhoneNumber(id: phone.sourceID, kind: phone.kind, value: value)
            },
            emails: emails.compactMap { Self.normalized($0.value) },
            website: Self.normalized(website),
            address: Self.normalized(address),
            unclassifiedText: source.fields.unclassifiedText
        )
    }

    /// Whether the corrected projection differs from the ORIGINAL
    /// extracted fields. Comparison runs on normalized values, so
    /// whitespace-only edits are not changes.
    var hasChanges: Bool {
        correctedFields != source.fields
    }

    /// Trims surrounding whitespace/newlines; returns nil when the
    /// result is empty.
    private static func normalized(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
