//
//  BusinessCardContactMapperTests.swift
//  SimCamCardTests
//
//  Week 4 Increment 11 — deterministic BusinessCard → ContactExportPayload
//  projection tests (T19, spec/reference-tests.md T19;
//  spec/data-model.md §Multi-value observation / §Missing-field rule).
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("BusinessCardContactMapper")
struct BusinessCardContactMapperTests {

    // MARK: - Fixtures

    private let phoneMobileID = UUID(uuidString: "A1000001-0000-0000-0000-000000000001")!
    private let phoneOfficeID = UUID(uuidString: "A1000001-0000-0000-0000-000000000002")!
    private let phoneFaxID = UUID(uuidString: "A1000001-0000-0000-0000-000000000003")!
    private let phoneOtherID = UUID(uuidString: "A1000001-0000-0000-0000-000000000004")!

    private func makeFullCard() -> BusinessCard {
        BusinessCard(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
            originalImageReference: "exp-original",
            processedImageReference: "exp-processed",
            rawOCRText: "RAW-OCR-SHOULD-NOT-LEAK",
            name: "陈晨",
            company: "上海智云科技有限公司",
            jobTitle: "商务拓展经理",
            website: "www.zhiyuntech.com",
            address: "中国 上海市 徐汇区漕溪北路398号 200030",
            phones: [
                PhoneNumber(id: phoneMobileID, kind: .mobile, value: "+86 136 8888 1024"),
                PhoneNumber(id: phoneOfficeID, kind: .office, value: "+86 (21) 5666 7788"),
                PhoneNumber(id: phoneFaxID, kind: .fax, value: "+86 (21) 5666 7799"),
                PhoneNumber(id: phoneOtherID, kind: .other, value: "400-800-9000"),
            ],
            emails: [
                "chen.chen@zhiyuntech.com",
                "second@zhiyuntech.com"
            ],
            tags: [CardTag(name: "客户")],
            notes: [CardNote(text: "内部备注不应导出")],
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
    }

    // MARK: - Full mapping

    @Test("full card maps name, company and job title unchanged")
    func fullCardMapsScalarFields() {
        let payload = BusinessCardContactMapper.map(makeFullCard())
        #expect(payload.name == "陈晨")
        #expect(payload.company == "上海智云科技有限公司")
        #expect(payload.jobTitle == "商务拓展经理")
    }

    @Test("all four phone kinds map with values preserved")
    func mapsAllPhoneKinds() {
        let payload = BusinessCardContactMapper.map(makeFullCard())
        #expect(payload.phones.map(\.kind) == [.mobile, .office, .fax, .other])
        #expect(payload.phones.map(\.value) == [
            "+86 136 8888 1024",
            "+86 (21) 5666 7788",
            "+86 (21) 5666 7799",
            "400-800-9000"
        ])
    }

    @Test("multiple phones preserve order including repeated kinds")
    func multiplePhonesPreserveOrder() {
        var card = makeFullCard()
        card.phones = [
            PhoneNumber(kind: .office, value: "OFFICE-1"),
            PhoneNumber(kind: .mobile, value: "MOBILE-1"),
            PhoneNumber(kind: .office, value: "OFFICE-2")
        ]
        let payload = BusinessCardContactMapper.map(card)
        #expect(payload.phones.map(\.value) == ["OFFICE-1", "MOBILE-1", "OFFICE-2"])
        #expect(payload.phones.map(\.kind) == [.office, .mobile, .office])
    }

    @Test("multiple emails preserve order")
    func multipleEmailsPreserveOrder() {
        let payload = BusinessCardContactMapper.map(makeFullCard())
        #expect(payload.emails == [
            "chen.chen@zhiyuntech.com",
            "second@zhiyuntech.com"
        ])
    }

    @Test("address is carried as the exact single string")
    func addressIsExactSingleString() {
        let payload = BusinessCardContactMapper.map(makeFullCard())
        #expect(payload.address == "中国 上海市 徐汇区漕溪北路398号 200030")
    }

    // MARK: - Minimal card / missing fields

    @Test("minimal card maps only name + mobile; every other field stays absent")
    func minimalCardKeepsMissingFieldsAbsent() {
        let card = BusinessCard(
            id: UUID(),
            originalImageReference: "min-original",
            processedImageReference: "min-processed",
            name: "张伟",
            phones: [PhoneNumber(kind: .mobile, value: "13800138000")]
        )
        let payload = BusinessCardContactMapper.map(card)

        #expect(payload == ContactExportPayload(
            name: "张伟",
            company: nil,
            jobTitle: nil,
            phones: [ContactExportPhone(kind: .mobile, value: "13800138000")],
            emails: [],
            address: nil
        ))
        #expect(payload.company == nil)
        #expect(payload.jobTitle == nil)
        #expect(payload.address == nil)
        #expect(payload.emails.isEmpty)
        #expect(payload.phones.count == 1)
    }

    @Test("nil scalars and empty arrays stay nil/empty — no fabricated values")
    func nilStaysNilAndEmptyStaysEmpty() {
        let card = BusinessCard(
            id: UUID(),
            originalImageReference: "x",
            processedImageReference: "y",
            name: nil,
            company: nil,
            jobTitle: nil,
            website: nil,
            address: nil,
            phones: [],
            emails: []
        )
        let payload = BusinessCardContactMapper.map(card)
        #expect(payload.name == nil)
        #expect(payload.company == nil)
        #expect(payload.jobTitle == nil)
        #expect(payload.address == nil)
        #expect(payload.phones == [])
        #expect(payload.emails == [])
    }

    // MARK: - Exclusion / determinism

    @Test("payload structurally contains only the six frozen T19 field groups")
    func payloadExcludesNonFrozenFields() {
        let card = makeFullCard()
        let payload = BusinessCardContactMapper.map(card)

        // The frozen payload type exposes ONLY name/company/jobTitle/
        // phones/emails/address — identity, image refs, rawOCRText,
        // website, tags, notes and timestamps cannot leak into it.
        // Mirror the expected projection exactly; equality failure here
        // means an extra/changed field value entered the export boundary.
        let expected = ContactExportPayload(
            name: "陈晨",
            company: "上海智云科技有限公司",
            jobTitle: "商务拓展经理",
            phones: [
                ContactExportPhone(kind: .mobile, value: "+86 136 8888 1024"),
                ContactExportPhone(kind: .office, value: "+86 (21) 5666 7788"),
                ContactExportPhone(kind: .fax, value: "+86 (21) 5666 7799"),
                ContactExportPhone(kind: .other, value: "400-800-9000"),
            ],
            emails: ["chen.chen@zhiyuntech.com", "second@zhiyuntech.com"],
            address: "中国 上海市 徐汇区漕溪北路398号 200030"
        )
        #expect(payload == expected)
    }

    @Test("mapping uses the final corrected values of the aggregate")
    func correctedTitleIsUsed() {
        var card = makeFullCard()
        card.jobTitle = "最终修正后的职位"
        card.emails = ["corrected@example.com"]
        let payload = BusinessCardContactMapper.map(card)
        #expect(payload.jobTitle == "最终修正后的职位")
        #expect(payload.emails == ["corrected@example.com"])
    }

    @Test("mapping is a deterministic pure function")
    func sameInputProducesSamePayload() {
        let card = makeFullCard()
        #expect(BusinessCardContactMapper.map(card) == BusinessCardContactMapper.map(card))
    }
}
