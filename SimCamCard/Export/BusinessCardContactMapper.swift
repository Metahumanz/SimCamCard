//
//  BusinessCardContactMapper.swift
//  SimCamCard
//
//  Week 4 Increment 11 — T19 Contact Export.
//
//  Deterministic, side-effect-free projection from the FINAL CORRECTED
//  BusinessCard aggregate to a ContactExportPayload (spec/reference-tests
//  .md T19; spec/data-model.md §Multi-value observation, §Missing-field
//  rule).
//
//  Lossless rules:
//   - nil scalars stay nil; empty phone/email arrays stay empty.
//   - phone order and kinds are preserved element-for-element; multiple
//     phones of the same kind are never collapsed.
//   - email order is preserved.
//   - the single address String is carried whole.
//
//  Deliberately NOT done here:
//   - splitting a Chinese name into surname/given name;
//   - parsing the company line;
//   - destructively normalizing phone strings;
//   - heuristically splitting the address into province/city/postcode;
//   - mapping website (frozen T19 excludes it even though the Reference
//     app shows a 主页 row — recorded as a Reference observation).
//

import Foundation

nonisolated enum BusinessCardContactMapper {

    /// Projects the six frozen T19 field groups. Every other domain
    /// field (image refs, rawOCRText, website, tags, notes, identity and
    /// timestamps) is intentionally absent from the payload.
    static func map(_ card: BusinessCard) -> ContactExportPayload {
        ContactExportPayload(
            name: card.name,
            company: card.company,
            jobTitle: card.jobTitle,
            phones: card.phones.map {
                ContactExportPhone(kind: $0.kind, value: $0.value)
            },
            emails: card.emails,
            address: card.address
        )
    }
}
