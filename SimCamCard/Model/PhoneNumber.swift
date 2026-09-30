//
//  PhoneNumber.swift
//  SimCamCard
//
//  Domain value representing a single phone number on a business card.
//  Spec source: spec/data-model.md §Multi-value observation
//  Revision constraint: phones[] is the single source of truth for phone numbers
//                       (no mobile/officePhone/fax single-value properties).
//

import Foundation

nonisolated struct PhoneNumber: Identifiable, Sendable, Hashable {

    /// Semantic kind of a phone number, matching
    /// spec/data-model.md §Multi-value observation: "mobile / office / fax / other".
    enum Kind: String, Sendable, Hashable, CaseIterable {
        case mobile
        case office
        case fax
        case other
    }

    let id: UUID
    var kind: Kind
    var value: String

    init(id: UUID = UUID(), kind: Kind, value: String) {
        self.id = id
        self.kind = kind
        self.value = value
    }
}
