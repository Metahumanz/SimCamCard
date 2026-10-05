//
//  SystemContactMapper.swift
//  SimCamCard
//
//  Week 4 Increment 11 — T19 Contact Export.
//
//  Pure, deterministic ContactExportPayload → CNMutableContact mapping.
//  Extracted as a separate helper so the six-field T19 mapping can be
//  unit-tested EXACTLY (values + Contacts labels + counts) without any
//  permission prompt or CNContactStore involvement.
//
//  Mapping decisions (see ai/changes.md W4I11 Reference observations):
//   - name: the full unsplit string goes into ONE Contacts name
//     property (`givenName`). The Domain only knows a complete name and
//     the frozen spec forbids guessing surname/given; Contacts displays
//     `givenName` alone as the contact's full display name.
//   - company → organizationName; jobTitle → jobTitle.
//   - ALL phones are written, kind labels:
//       mobile → CNLabelPhoneNumberMobile      （手机）
//       office → CNLabelWork                   （工作， work-compatible）
//       fax    → CNLabelPhoneNumberWorkFax     （工作传真）
//       other  → CNLabelOther                  （其他）
//   - ALL emails are written. BusinessCard.emails carries no kind and
//     the frozen T19 spec only requires value survival, so no work/home
//     label is fabricated: CNLabelOther is used. (REF-export-04/05 show
//     a 工作 label in the reference app — recorded fidelity gap.)
//   - address: the single Domain String is written WHOLE into
//     CNMutablePostalAddress.street with CNLabelOther; it is never split
//     into country/state/city/postalCode heuristically.
//

import Contacts
import Foundation

nonisolated enum SystemContactMapper {

    /// Builds an unsaved mutable contact. No system side effect happens
    /// here; SystemContactExporter owns the CNSaveRequest.
    static func makeContact(from payload: ContactExportPayload) -> CNMutableContact {
        let contact = CNMutableContact()

        if let name = payload.name {
            contact.givenName = name
        }
        if let company = payload.company {
            contact.organizationName = company
        }
        if let jobTitle = payload.jobTitle {
            contact.jobTitle = jobTitle
        }

        contact.phoneNumbers = payload.phones.map { phone in
            CNLabeledValue(
                label: Self.cnLabel(for: phone.kind),
                value: CNPhoneNumber(stringValue: phone.value)
            )
        }

        contact.emailAddresses = payload.emails.map { email in
            CNLabeledValue(label: CNLabelOther, value: email as NSString)
        }

        if let address = payload.address {
            let postal = CNMutablePostalAddress()
            // Lossless single-string placement: no province/city/postcode
            // guessing (Domain has one address string only).
            postal.street = address
            contact.postalAddresses = [
                CNLabeledValue(label: CNLabelOther, value: postal)
            ]
        }

        return contact
    }

    /// Deterministic Domain phone kind → Contacts label mapping.
    static func cnLabel(for kind: PhoneNumber.Kind) -> String {
        switch kind {
        case .mobile:
            CNLabelPhoneNumberMobile
        case .office:
            CNLabelWork
        case .fax:
            CNLabelPhoneNumberWorkFax
        case .other:
            CNLabelOther
        }
    }
}
