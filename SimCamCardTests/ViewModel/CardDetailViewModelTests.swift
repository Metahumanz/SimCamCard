//
//  CardDetailViewModelTests.swift
//  SimCamCardTests
//
//  Unit tests for CardDetailViewModel (Swift Testing).
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail
//   - spec/state-inventory.md S06 detailCollapsed
//   - spec/reference-tests.md T13 Detail (saved structured fields visible)
//   - spec/data-model.md §Multi-value observation, §Missing-field rule
//
//  What is verified:
//   - The read-only ViewModel holds the exact BusinessCard value it was
//     initialized with — no DTO remapping, no dropped or fabricated fields.
//   - Multi-value collections (phones[] with distinct kinds, emails[])
//     survive without loss.
//   - The Card 004 minimal fixture exposes ONLY name + mobile; absent
//     structured fields remain nil/empty (T20 negative case).
//

import Testing
import Foundation
@testable import SimCamCard

@MainActor
@Suite("CardDetailViewModel")
struct CardDetailViewModelTests {

    // MARK: - Multi-value field preservation (always compiled)

    @Test("all phone kinds and multiple emails are preserved without loss")
    func multiValueFieldsArePreservedWithoutLoss() {
        let id = UUID()
        let card = BusinessCard(
            id: id,
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            name: "多值测试",
            company: "示例公司",
            jobTitle: "经理",
            website: "example.com",
            address: "示例地址",
            phones: [
                PhoneNumber(id: UUID(), kind: .mobile, value: "13800000000"),
                PhoneNumber(id: UUID(), kind: .office, value: "02111111111"),
                PhoneNumber(id: UUID(), kind: .fax, value: "02122222222"),
            ],
            emails: ["one@example.com", "two@example.com"]
        )

        let viewModel = CardDetailViewModel(card: card)
        let displayed = viewModel.card

        #expect(displayed.id == id)
        #expect(displayed.phones.count == 3)
        #expect(displayed.phones.map(\.kind) == [.mobile, .office, .fax])
        #expect(displayed.phones.map(\.value) == [
            "13800000000", "02111111111", "02122222222"
        ])
        #expect(displayed.emails == ["one@example.com", "two@example.com"])
    }

    // MARK: - Deterministic fixtures (DEBUG-only; MockBusinessCards is
    // compiled out of Release)

    #if DEBUG

    @Test("full fixture card 001 exposes every structured Domain value")
    func fullFixtureExposesAllStructuredValues() {
        let viewModel = CardDetailViewModel(card: MockBusinessCards.card001)
        let card = viewModel.card

        // Identity
        #expect(card.id == MockBusinessCards.card001ID)

        // Header fields
        #expect(card.name == "张伟")
        #expect(card.jobTitle == "产品总监 | Product Director")
        #expect(card.company == "上海智云科技有限公司")

        // Contact fields
        #expect(card.website == "www.zhiyuntech.com")
        #expect(card.address == "上海市浦东新区世纪大道100号 200120")
        #expect(card.emails == ["wei.zhang@zhiyuntech.com"])

        // Multi-phone: both kinds and values preserved
        #expect(card.phones.count == 2)
        #expect(card.phones(of: .mobile).map(\.value) == ["+86 138 0013 8000"])
        #expect(card.phones(of: .office).map(\.value) == ["+86 21 5555 1234"])

        // The ViewModel must expose the SAME value type, not a copy/DTO:
        #expect(card == MockBusinessCards.card001)
    }

    @Test("minimal fixture card 004 preserves only name and mobile and fabricates nothing")
    func minimalFixtureDoesNotFabricateMissingFields() {
        let viewModel = CardDetailViewModel(card: MockBusinessCards.card004)
        let card = viewModel.card

        // Present fields
        #expect(card.name == "张伟")
        #expect(card.phones.count == 1)
        #expect(card.phones.first?.kind == .mobile)
        #expect(card.phones.first?.value == "+86 138 0013 8000")

        // Absent structured fields stay nil/empty — no fabrication
        // (spec/data-model.md §Missing-field rule; T20 Card 004).
        #expect(card.company == nil)
        #expect(card.jobTitle == nil)
        #expect(card.website == nil)
        #expect(card.address == nil)
        #expect(card.emails.isEmpty)
        #expect(card.phones(of: .office).isEmpty)
        #expect(card.phones(of: .fax).isEmpty)
        #expect(card.tags.isEmpty)
        #expect(card.notes.isEmpty)
    }

    #endif
}
