//
//  StructuredCardFields.swift
//  SimCamCard
//
//  Week 4 Increment 1 — T08/T09/T10 structured extraction core.
//
//  Structured fields DERIVED FROM raw OCR lines. This is a PIPELINE
//  INTERMEDIATE value, not the frozen BusinessCard domain entity:
//  no id, no image references, no tags/notes, no persistence, no
//  Repository involvement.
//
//  Frozen-domain discipline (spec/data-model.md):
//   - nameLatin / companyLatin / department / languageProfile are NOT
//     added here. Latin counterparts of bilingual cards stay in
//     `unclassifiedText` as preserved evidence for the later manual
//     correction increment.
//   - phones: [PhoneNumber] is the single source of truth for phone
//     numbers (mobile / office / fax / other). No single-value
//     mobile/phone/fax properties are reintroduced.
//   - Missing-field rule: absent values are nil / empty, never
//     fabricated (T09).
//

import Foundation

nonisolated struct StructuredCardFields: Sendable, Equatable {

    /// Canonical person name. On bilingual cards the native/canonical
    /// form is preferred (e.g. 张伟 over "Wei Zhang").
    var name: String?

    /// Canonical organization name. Native form preferred on
    /// bilingual cards; the English counterpart is left in
    /// `unclassifiedText`.
    var company: String?

    /// Job title, preserving the OCR value (e.g. the bilingual
    /// "产品总监 | Product Director" single-line form).
    var jobTitle: String?

    /// All classified phone numbers in OCR encounter order. The
    /// single phone source of truth (spec/data-model.md
    /// §Multi-value observation).
    var phones: [PhoneNumber]

    /// All email addresses in OCR encounter order, exact duplicates
    /// removed.
    var emails: [String]

    /// First recognized website/URL token. Never derived from an
    /// email domain (T09 no-fabrication rule).
    var website: String?

    /// Address text with its label removed (possible deterministic
    /// multi-line continuation joined with spaces).
    var address: String?

    /// Raw line texts that were not classified into a typed field,
    /// preserved in OCR encounter order (e.g. Latin counterparts,
    /// slogans, unlabeled ambiguous lines).
    var unclassifiedText: [String]

    init(
        name: String? = nil,
        company: String? = nil,
        jobTitle: String? = nil,
        phones: [PhoneNumber] = [],
        emails: [String] = [],
        website: String? = nil,
        address: String? = nil,
        unclassifiedText: [String] = []
    ) {
        self.name = name
        self.company = company
        self.jobTitle = jobTitle
        self.phones = phones
        self.emails = emails
        self.website = website
        self.address = address
        self.unclassifiedText = unclassifiedText
    }

    // MARK: - Phone accessors
    //
    // Kind-filtered accessors only (mirrors the BusinessCard domain
    // rule): multiple numbers of the same kind are preserved.

    /// All phone numbers matching the given kind, in stored order.
    func phones(of kind: PhoneNumber.Kind) -> [PhoneNumber] {
        phones.filter { $0.kind == kind }
    }
}
