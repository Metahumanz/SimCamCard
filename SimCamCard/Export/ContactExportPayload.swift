//
//  ContactExportPayload.swift
//  SimCamCard
//
//  Week 4 Increment 11 — T19 Contact Export.
//
//  Pure-Swift export boundary between the BusinessCard aggregate and the
//  Contacts-framework mapping layer. It carries ONLY the six frozen T19
//  field groups (name / company / jobTitle / phones / emails / address);
//  it deliberately has no card id, image references, raw OCR, tags,
//  notes or website (spec/reference-tests.md T19).
//
//  Contact export is an EXTERNAL SIDE EFFECT: the payload does not feed
//  back into the BusinessCard aggregate, is never persisted by the card
//  repository, and the Domain layer gains no CNContact/Codable/
//  contactIdentifier/exported-flag property.
//

import Foundation

/// A single phone value plus its Domain kind, ready for Contacts
/// labeling. A payload may carry several of these (including multiple
/// values sharing one kind); order is significant and preserved.
nonisolated struct ContactExportPhone: Sendable, Equatable {

    /// Semantic kind inherited unchanged from `PhoneNumber.Kind`.
    var kind: PhoneNumber.Kind

    /// The exact corrected display value from the BusinessCard. It is
    /// never destructively normalized; `CNPhoneNumber` keeps it verbatim.
    var value: String

    init(kind: PhoneNumber.Kind, value: String) {
        self.kind = kind
        self.value = value
    }
}

/// The frozen T19 export projection of one BusinessCard.
/// `nil` scalars stay `nil` and empty collections stay empty — the
/// mapping never fabricates placeholder values (spec/data-model.md
/// §Missing-field rule).
nonisolated struct ContactExportPayload: Sendable, Equatable {

    /// Full, unsplit name string (Chinese names are never broken into
    /// surname/given).
    var name: String?

    var company: String?
    var jobTitle: String?

    /// All phone values in BusinessCard storage order, kinds preserved.
    var phones: [ContactExportPhone]

    /// All email values in BusinessCard storage order.
    var emails: [String]

    /// The single unsplit address string. It is written losslessly into
    /// one Contacts postal-address property; no city/province/postal
    /// heuristics are applied.
    var address: String?

    init(
        name: String? = nil,
        company: String? = nil,
        jobTitle: String? = nil,
        phones: [ContactExportPhone] = [],
        emails: [String] = [],
        address: String? = nil
    ) {
        self.name = name
        self.company = company
        self.jobTitle = jobTitle
        self.phones = phones
        self.emails = emails
        self.address = address
    }
}
