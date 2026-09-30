//
//  BusinessCard.swift
//  SimCamCard
//
//  Domain entity representing a single digitized business card.
//  Spec source: spec/data-model.md §BusinessCard, §Multi-value observation,
//               §Missing-field rule, §OCR Pipeline Data
//  Revision constraints:
//   - Model does not depend on UIKit / SwiftUI.
//   - originalImage / processedImage are REQUIRED String reference fields
//     per spec/data-model.md §BusinessCard (no UIImage; not Optional —
//     implementation must not relax a frozen spec invariant).
//   - rawOCRText is an optional domain field; Week 2 default is nil.
//   - phones: [PhoneNumber] is the single source of truth; no single-value
//     mobile / officePhone / fax properties.
//   - nameLatin / companyLatin / department / languageProfile are present in
//     ground-truth JSON but not in spec/data-model.md minimum field table;
//     per Revision 8 they are NOT added here and are recorded as
//     specification clarifications.
//

import Foundation

nonisolated struct BusinessCard: Identifiable, Sendable, Hashable {

    /// Stable system identifier. Spec §BusinessCard minimum field table:
    /// "id | stable identifier | Yes | System".
    let id: UUID

    /// Reference token (e.g. asset name, file path, or image ID) to the
    /// original captured/imported image.
    /// Spec §BusinessCard minimum field table: "originalImage | image
    /// reference | Yes | Capture/Import". Required by the frozen spec;
    /// stored as a String reference, never a UIKit image type.
    /// Test/preview fixtures supply deterministic tokens such as
    /// "card-001-original".
    var originalImageReference: String

    /// Reference token to the processed/corrected image.
    /// Spec §BusinessCard minimum field table: "processedImage | image
    /// reference | Yes | Crop/Correction". Required by the frozen spec;
    /// stored as a String reference, never a UIKit image type.
    /// Test/preview fixtures supply deterministic tokens such as
    /// "card-001-processed".
    var processedImageReference: String

    /// Raw OCR text. Spec: "Yes after OCR". Week 2 has no OCR pipeline,
    /// so default is nil. Field exists to preserve interface shape per
    /// ai/prompts/week2-skeleton.md ("Preserve interfaces once tests
    /// depend on them").
    var rawOCRText: String?

    /// Optional structured fields. Per spec §Missing-field rule, absent
    /// values must be nil rather than fabricated.
    var name: String?
    var company: String?
    var jobTitle: String?
    var website: String?
    var address: String?

    /// Phone numbers. Single source of truth per Revision 9.
    /// A card may carry multiple numbers of the same Kind; do not collapse
    /// them into single-value mobile/phone/fax properties.
    /// Spec source: spec/data-model.md §Multi-value observation
    /// ("phones[] with kind = mobile / office / fax / other").
    var phones: [PhoneNumber]

    /// Email addresses. Spec §Multi-value observation: "potentially
    /// multiple email addresses" + "emails[]". See spec clarification §4
    /// for tension with minimum field table's email: text?.
    var emails: [String]

    /// Tags/groups attached to this card. Spec §BusinessCard
    /// ("tags: collection"). Group management UI is deferred.
    var tags: [CardTag]

    /// Notes attached to this card. Spec §BusinessCard
    /// ("notes: collection"). Note add/edit UI is deferred.
    var notes: [CardNote]

    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        originalImageReference: String,
        processedImageReference: String,
        rawOCRText: String? = nil,
        name: String? = nil,
        company: String? = nil,
        jobTitle: String? = nil,
        website: String? = nil,
        address: String? = nil,
        phones: [PhoneNumber] = [],
        emails: [String] = [],
        tags: [CardTag] = [],
        notes: [CardNote] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.originalImageReference = originalImageReference
        self.processedImageReference = processedImageReference
        self.rawOCRText = rawOCRText
        self.name = name
        self.company = company
        self.jobTitle = jobTitle
        self.website = website
        self.address = address
        self.phones = phones
        self.emails = emails
        self.tags = tags
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Phone accessors
//
// Per Revision 9: do NOT expose single-value mobile/officePhone/fax
// properties (they would discard multiple numbers of the same kind).
// Provide kind-filtered accessors only.

nonisolated extension BusinessCard {

    /// All phone numbers matching the given kind.
    /// Order is preserved as stored in `phones`.
    func phones(of kind: PhoneNumber.Kind) -> [PhoneNumber] {
        phones.filter { $0.kind == kind }
    }

    /// First phone number of the given kind, or nil if none.
    func firstPhone(of kind: PhoneNumber.Kind) -> PhoneNumber? {
        phones.first { $0.kind == kind }
    }
}
