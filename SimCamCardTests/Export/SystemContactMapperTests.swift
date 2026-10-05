//
//  SystemContactMapperTests.swift
//  SimCamCardTests
//
//  Week 4 Increment 11 — exact ContactExportPayload → CNMutableContact
//  mapping tests (T19). These tests prove the six frozen field groups,
//  Contacts labels and multi-value preservation WITHOUT any permission
//  prompt or CNContactStore involvement, so field-level acceptance does
//  not depend on simulator authorization state.
//
//  Reference target: REF-export-04/05 (陈晨 card — mobile + office +
//  work fax, one work email, multiline work address).
//

import Testing
import Foundation
import Contacts
@testable import SimCamCard

@Suite("SystemContactMapper")
struct SystemContactMapperTests {

    // MARK: - Card 003 shape: full mapping

    private func makeFullPayload() -> ContactExportPayload {
        ContactExportPayload(
            name: "陈晨",
            company: "上海智云科技有限公司",
            jobTitle: "商务拓展经理 Business Development Manager",
            phones: [
                ContactExportPhone(kind: .mobile, value: "+86 136 8888 1024"),
                ContactExportPhone(kind: .office, value: "+86 (21) 5666 7788"),
                ContactExportPhone(kind: .fax, value: "+86 (21) 5666 7799"),
            ],
            emails: ["chen.chen@zhiyuntech.com"],
            address: "中国 上海市 徐汇区漕溪北路398号 200030"
        )
    }

    @Test("full name is preserved verbatim in one Contacts name property")
    func nameMapsToSingleProperty() {
        let contact = SystemContactMapper.makeContact(from: makeFullPayload())
        #expect(contact.givenName == "陈晨")
        // Chinese names are never split; familyName/middle are untouched.
        #expect(contact.familyName.isEmpty)
        #expect(contact.middleName.isEmpty)
    }

    @Test("company maps to organizationName")
    func companyMaps() {
        let contact = SystemContactMapper.makeContact(from: makeFullPayload())
        #expect(contact.organizationName == "上海智云科技有限公司")
    }

    @Test("job title maps to jobTitle")
    func jobTitleMaps() {
        let contact = SystemContactMapper.makeContact(from: makeFullPayload())
        #expect(contact.jobTitle == "商务拓展经理 Business Development Manager")
    }

    @Test("ALL phones map with exact values and deterministic Contacts labels")
    func phoneValuesAndLabelsMap() {
        let contact = SystemContactMapper.makeContact(from: makeFullPayload())

        #expect(contact.phoneNumbers.count == 3)

        let mobile = contact.phoneNumbers[0]
        #expect(mobile.label == CNLabelPhoneNumberMobile)
        #expect((mobile.value as! CNPhoneNumber).stringValue == "+86 136 8888 1024")

        let office = contact.phoneNumbers[1]
        #expect(office.label == CNLabelWork)
        #expect((office.value as! CNPhoneNumber).stringValue == "+86 (21) 5666 7788")

        let fax = contact.phoneNumbers[2]
        #expect(fax.label == CNLabelPhoneNumberWorkFax)
        #expect((fax.value as! CNPhoneNumber).stringValue == "+86 (21) 5666 7799")
    }

    @Test("repeated and 'other' phone kinds all survive with order preserved")
    func repeatedAndOtherPhonesSurvive() {
        var payload = makeFullPayload()
        payload.phones = [
            ContactExportPhone(kind: .office, value: "O1"),
            ContactExportPhone(kind: .other, value: "X1"),
            ContactExportPhone(kind: .office, value: "O2")
        ]
        let contact = SystemContactMapper.makeContact(from: payload)
        #expect(contact.phoneNumbers.map { ($0.value as! CNPhoneNumber).stringValue } == ["O1", "X1", "O2"])
        #expect(contact.phoneNumbers.map(\.label) == [CNLabelWork, CNLabelOther, CNLabelWork])
    }

    @Test("ALL emails survive; Domain has no email kind so CNLabelOther is used")
    func emailsMapWithoutFabricatedKind() {
        var payload = makeFullPayload()
        payload.emails = ["one@example.com", "two@example.com"]
        let contact = SystemContactMapper.makeContact(from: payload)

        #expect(contact.emailAddresses.count == 2)
        #expect(contact.emailAddresses.map { $0.value as String } == [
            "one@example.com", "two@example.com"
        ])
        #expect(contact.emailAddresses.map(\.label) == [CNLabelOther, CNLabelOther])
    }

    @Test("the single address string is stored whole in postal street")
    func addressMapsWholeIntoStreet() {
        let contact = SystemContactMapper.makeContact(from: makeFullPayload())

        #expect(contact.postalAddresses.count == 1)
        let labeled = contact.postalAddresses[0]
        #expect(labeled.label == CNLabelOther)
        let postal = labeled.value as! CNPostalAddress
        #expect(postal.street == "中国 上海市 徐汇区漕溪北路398号 200030")
        // No city/province/postcode guessing from the single Domain string.
        #expect(postal.city.isEmpty)
        #expect(postal.state.isEmpty)
        #expect(postal.postalCode.isEmpty)
        #expect(postal.country.isEmpty)
    }

    // MARK: - Minimal card / missing fields

    @Test("minimal payload produces only name + one mobile contact")
    func minimalPayloadMapping() {
        let payload = ContactExportPayload(
            name: "张伟",
            phones: [ContactExportPhone(kind: .mobile, value: "13800138000")]
        )
        let contact = SystemContactMapper.makeContact(from: payload)

        #expect(contact.givenName == "张伟")
        #expect(contact.organizationName.isEmpty)
        #expect(contact.jobTitle.isEmpty)
        #expect(contact.phoneNumbers.count == 1)
        #expect((contact.phoneNumbers[0].value as! CNPhoneNumber).stringValue == "13800138000")
        #expect(contact.phoneNumbers[0].label == CNLabelPhoneNumberMobile)
        #expect(contact.emailAddresses.isEmpty)
        #expect(contact.postalAddresses.isEmpty)
    }

    @Test("missing name yields an empty contact name (never fabricated)")
    func missingNameIsNotFabricated() {
        var payload = makeFullPayload()
        payload.name = nil
        let contact = SystemContactMapper.makeContact(from: payload)
        #expect(contact.givenName.isEmpty)
        #expect(contact.familyName.isEmpty)
        // The remaining provided fields still map normally.
        #expect(contact.organizationName == "上海智云科技有限公司")
        #expect(contact.phoneNumbers.count == 3)
    }

    @Test("nil/empty optional fields create no placeholder entries")
    func emptyFieldsCreateNoPlaceholders() {
        let contact = SystemContactMapper.makeContact(from: ContactExportPayload())
        #expect(contact.givenName.isEmpty)
        #expect(contact.organizationName.isEmpty)
        #expect(contact.jobTitle.isEmpty)
        #expect(contact.phoneNumbers.isEmpty)
        #expect(contact.emailAddresses.isEmpty)
        #expect(contact.postalAddresses.isEmpty)
    }

    // MARK: - Authorization status mapping

    @Test("CNAuthorizationStatus maps limited/authorized to allowed and others to denied")
    func authorizationStatusMapping() {
        #expect(SystemContactExporter.map(.notDetermined) == .notDetermined)
        #expect(SystemContactExporter.map(.denied) == .denied)
        #expect(SystemContactExporter.map(.restricted) == .denied)
        #expect(SystemContactExporter.map(.authorized) == .allowed)
        #expect(SystemContactExporter.map(.limited) == .allowed)
    }
}
