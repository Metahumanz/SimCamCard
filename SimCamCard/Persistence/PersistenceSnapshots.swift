//
//  PersistenceSnapshots.swift
//  SimCamCard
//
//  Week 4 Increment 9 — persistence-only Codable documents for T18.
//
//  CRITICAL DESIGN RULE: the frozen Domain Model
//  (BusinessCard / PhoneNumber / CardTag / CardNote) is NOT Codable and
//  is not modified by this increment. The types in this file are a
//  separate persistence data-transfer layer; mapping is pure and
//  deterministic in both directions:
//
//      Domain  ──BusinessCardSnapshot(_:)──▶  Snapshot  ──JSON──▶ disk
//      Domain  ◀──businessCard()──────────  Snapshot  ◀──JSON── disk
//
//  Round-trip preservation requirements (spec/state-inventory.md S10):
//  all identities (BusinessCard/PhoneNumber/CardTag/CardNote ids),
//  originalImageReference + processedImageReference, rawOCRText,
//  every structured field, phone kinds/values, emails, tags, notes,
//  createdAt and updatedAt.
//
//  Phone kind mapping is an EXHAUSTIVE switch on both sides — an
//  unknown/legacy raw value never silently collapses to `.other`.
//

import Foundation

// MARK: - On-disk documents

/// Top-level JSON document for cards (`cards.json`).
nonisolated struct BusinessCardStoreDocument: Codable, Sendable {

    /// On-disk schema version. Bumped only for an incompatible format
    /// change; the `v1` root directory segment is the matching namespace.
    var schemaVersion: Int

    var cards: [BusinessCardSnapshot]

    init(schemaVersion: Int = Self.currentSchemaVersion,
         cards: [BusinessCardSnapshot] = []) {
        self.schemaVersion = schemaVersion
        self.cards = cards
    }

    static let currentSchemaVersion = 1
}

/// Top-level JSON document for the group catalog (`groups.json`).
nonisolated struct CardGroupStoreDocument: Codable, Sendable {

    var schemaVersion: Int

    /// Authoritative catalog of ALL user-defined groups — including
    /// groups to which zero cards are currently assigned. This catalog
    /// is never rebuilt from cards.json tags.
    var groups: [CardTagSnapshot]

    init(schemaVersion: Int = Self.currentSchemaVersion,
         groups: [CardTagSnapshot] = []) {
        self.schemaVersion = schemaVersion
        self.groups = groups
    }

    static let currentSchemaVersion = 1
}

// MARK: - Record snapshots

nonisolated struct BusinessCardSnapshot: Codable, Sendable {
    var id: UUID
    var originalImageReference: String
    var processedImageReference: String
    var rawOCRText: String?
    var name: String?
    var company: String?
    var jobTitle: String?
    var website: String?
    var address: String?
    var phones: [PhoneNumberSnapshot]
    var emails: [String]
    var tags: [CardTagSnapshot]
    var notes: [CardNoteSnapshot]
    var createdAt: Date
    var updatedAt: Date

    /// Deterministic Domain → persistence mapping.
    init(_ card: BusinessCard) {
        self.id = card.id
        self.originalImageReference = card.originalImageReference
        self.processedImageReference = card.processedImageReference
        self.rawOCRText = card.rawOCRText
        self.name = card.name
        self.company = card.company
        self.jobTitle = card.jobTitle
        self.website = card.website
        self.address = card.address
        self.phones = card.phones.map(PhoneNumberSnapshot.init)
        self.emails = card.emails
        self.tags = card.tags.map(CardTagSnapshot.init)
        self.notes = card.notes.map(CardNoteSnapshot.init)
        self.createdAt = card.createdAt
        self.updatedAt = card.updatedAt
    }

    /// Persistence → Domain mapping. Preserves every field and
    /// identity exactly; synthesizes nothing (absent optionals decode
    /// as nil, matching the §Missing-field rule).
    func businessCard() -> BusinessCard {
        BusinessCard(
            id: id,
            originalImageReference: originalImageReference,
            processedImageReference: processedImageReference,
            rawOCRText: rawOCRText,
            name: name,
            company: company,
            jobTitle: jobTitle,
            website: website,
            address: address,
            phones: phones.map { $0.phoneNumber() },
            emails: emails,
            tags: tags.map { $0.cardTag() },
            notes: notes.map { $0.cardNote() },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

nonisolated struct PhoneNumberSnapshot: Codable, Sendable {
    var id: UUID
    var kind: PhoneKindSnapshot
    var value: String

    init(_ phone: PhoneNumber) {
        self.id = phone.id
        self.kind = PhoneKindSnapshot(phone.kind)
        self.value = phone.value
    }

    init(id: UUID, kind: PhoneKindSnapshot, value: String) {
        self.id = id
        self.kind = kind
        self.value = value
    }

    func phoneNumber() -> PhoneNumber {
        PhoneNumber(id: id, kind: PhoneNumber.Kind(kind), value: value)
    }
}

/// Persistence representation of `PhoneNumber.Kind`. Kept distinct
/// from the Domain enum so the frozen Domain type gains no
/// Codable/rawValue coupling.
nonisolated enum PhoneKindSnapshot: String, Codable, Sendable {
    case mobile
    case office
    case fax
    case other
}

nonisolated struct CardTagSnapshot: Codable, Sendable {
    var id: UUID
    var name: String

    init(_ tag: CardTag) {
        self.id = tag.id
        self.name = tag.name
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    func cardTag() -> CardTag {
        CardTag(id: id, name: name)
    }
}

nonisolated struct CardNoteSnapshot: Codable, Sendable {
    var id: UUID
    var text: String
    var createdAt: Date

    init(_ note: CardNote) {
        self.id = note.id
        self.text = note.text
        self.createdAt = note.createdAt
    }

    init(id: UUID, text: String, createdAt: Date) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }

    func cardNote() -> CardNote {
        CardNote(id: id, text: text, createdAt: createdAt)
    }
}

// MARK: - Exhaustive phone-kind mapping

nonisolated extension PhoneKindSnapshot {

    /// Exhaustive Domain → persistence mapping. Every Domain case is
    /// handled; adding a Domain case forces a compile error here.
    init(_ kind: PhoneNumber.Kind) {
        switch kind {
        case .mobile: self = .mobile
        case .office: self = .office
        case .fax: self = .fax
        case .other: self = .other
        }
    }
}

nonisolated extension PhoneNumber.Kind {

    /// Exhaustive persistence → Domain mapping. Every persisted case
    /// is handled explicitly; unknown raw values fail decoding at the
    /// Codable boundary instead of silently becoming `.other`.
    init(_ snapshot: PhoneKindSnapshot) {
        switch snapshot {
        case .mobile: self = .mobile
        case .office: self = .office
        case .fax: self = .fax
        case .other: self = .other
        }
    }
}

// MARK: - Shared JSON coding

/// JSON configuration shared by every File repository so cards.json
/// and groups.json use one identical encoding.
///
/// - UUIDs use their default stable string coding.
/// - Dates persist as `timeIntervalSinceReferenceDate` JSON Doubles.
///   A Swift `Date` IS an IEEE 754 Double offset from the reference
///   date; encoding that Double verbatim round-trips bit-exactly,
///   whereas ISO 8601 text (even with fractional seconds) truncates
///   sub-millisecond precision. Decoding is
///   `Date(timeIntervalSinceReferenceDate:)`.
nonisolated enum PersistenceJSON {

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSinceReferenceDate)
        }
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let interval = try container.decode(Double.self)
            return Date(timeIntervalSinceReferenceDate: interval)
        }
        return decoder
    }()
}
