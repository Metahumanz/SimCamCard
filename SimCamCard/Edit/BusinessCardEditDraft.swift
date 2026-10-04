//
//  BusinessCardEditDraft.swift
//  SimCamCard
//
//  Week 4 Increment 5 — T14 Existing-Card Editing intermediate.
//
//  The user-editable buffer for editing an ALREADY SAVED BusinessCard,
//  reached from Card Detail → 编辑. It is deliberately a separate type
//  from RecognitionDraft (T11):
//
//    RecognitionDraft.source = StructuredRecognitionResult
//
//  A saved BusinessCard has no OCR pipeline result — re-editing it must
//  NOT fabricate a CardOCRResult / CardCropResult /
//  StructuredRecognitionResult. BusinessCardEditDraft.source is the
//  saved BusinessCard aggregate itself.
//
//  Identity semantics differ from the new-scan Save path on purpose:
//   - Increment 4 (new scan → final card): final PhoneNumber IDs are
//     FRESH domain IDs, because a brand-new aggregate is born.
//   - Increment 5 (existing card edit): this is a mutation of the SAME
//     BusinessCard aggregate, so each existing PhoneNumber KEEPS its id;
//     only its value (and kind, if the UI ever edits it) changes.
//   The BusinessCard id, image references, rawOCRText, createdAt, tags
//   and notes are likewise carried through untouched.
//
//  Blank normalization matches RecognitionDraft: surrounding whitespace
//  is trimmed, an empty scalar becomes nil, and an empty phone/email row
//  is dropped. No placeholder content is fabricated.
//

import Foundation

nonisolated struct BusinessCardEditDraft: Sendable, Equatable {

    /// Editable phone row. `id` IS the saved PhoneNumber.id and stays
    /// stable through the edit — this is the same aggregate being
    /// modified, not a new finalization. Kind is carried but the T14
    /// UI edits values only.
    nonisolated struct PhoneField: Identifiable, Sendable, Equatable {
        let id: UUID
        var kind: PhoneNumber.Kind
        var value: String
    }

    /// The immutable saved card this draft was created from. Never
    /// mutated: identity and non-edited metadata stay reachable through
    /// it for the projection.
    let source: BusinessCard

    var name: String
    var company: String
    var jobTitle: String

    var phones: [PhoneField]
    var emails: [String]

    var website: String
    var address: String

    init(source: BusinessCard) {
        self.source = source
        self.name = source.name ?? ""
        self.company = source.company ?? ""
        self.jobTitle = source.jobTitle ?? ""
        self.phones = source.phones.map { phone in
            PhoneField(id: phone.id, kind: phone.kind, value: phone.value)
        }
        self.emails = source.emails
        self.website = source.website ?? ""
        self.address = source.address ?? ""
    }

    // MARK: - Updated projection

    /// Projects the edited strings back into an updated BusinessCard.
    ///
    /// Aggregate identity and non-edited metadata come from `source`
    /// unchanged:
    ///   id, originalImageReference, processedImageReference, rawOCRText,
    ///   createdAt, tags, notes.
    /// Only the user-editable fields are projected from the draft, and
    /// `updatedAt` is set to the supplied timestamp (the orchestrator
    /// owns the clock; this projection stays deterministic).
    func updatedCard(timestamp: Date) -> BusinessCard {
        BusinessCard(
            id: source.id,
            originalImageReference: source.originalImageReference,
            processedImageReference: source.processedImageReference,
            rawOCRText: source.rawOCRText,
            name: Self.normalized(name),
            company: Self.normalized(company),
            jobTitle: Self.normalized(jobTitle),
            website: Self.normalized(website),
            address: Self.normalized(address),
            phones: phones.compactMap { phone in
                guard let value = Self.normalized(phone.value) else { return nil }
                // Existing saved phone identity is preserved.
                return PhoneNumber(id: phone.id, kind: phone.kind, value: value)
            },
            emails: emails.compactMap { Self.normalized($0) },
            tags: source.tags,
            notes: source.notes,
            createdAt: source.createdAt,
            updatedAt: timestamp
        )
    }

    /// Whether the normalized projection differs from the saved card's
    /// editable values. Comparison excludes `updatedAt` (a timestamp is
    /// metadata maintenance, not a user change) and all non-edited
    /// metadata.
    var hasChanges: Bool {
        let projected = updatedCard(timestamp: source.updatedAt)
        return projected.name != source.name
            || projected.company != source.company
            || projected.jobTitle != source.jobTitle
            || projected.website != source.website
            || projected.address != source.address
            || projected.phones != source.phones
            || projected.emails != source.emails
    }

    /// Trims surrounding whitespace/newlines; returns nil when the
    /// result is empty.
    private static func normalized(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
