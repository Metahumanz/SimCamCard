//
//  BusinessCardTests.swift
//  SimCamCardTests
//
//  Unit tests for BusinessCard domain entity.
//  Spec sources:
//   - spec/data-model.md §BusinessCard (minimum field table)
//   - spec/data-model.md §Multi-value observation (phones[]/emails[])
//   - spec/data-model.md §Missing-field rule (card-002, card-004)
//  Ground-truth fixtures used as shape references (not exact copies):
//   - card-001: full bilingual card
//   - card-002: missing website
//   - card-004: only name + mobile
//   - card-011: mobile + office + fax
//
//  Image references are REQUIRED per spec/data-model.md §BusinessCard
//  (originalImage / processedImage: Yes). Every fixture supplies
//  deterministic String tokens, e.g. "card-001-original".
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("BusinessCard")
struct BusinessCardTests {

    // MARK: - Initialization

    @Test("init with required references leaves optional fields nil and collections empty")
    func initWithRequiredReferencesLeavesOptionalsNilAndCollectionsEmpty() throws {
        let card = BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed"
        )
        #expect(card.id != UUID()) // generated
        // Required image references are present String tokens.
        #expect(card.originalImageReference == "test-original")
        #expect(card.processedImageReference == "test-processed")
        #expect(card.rawOCRText == nil)
        #expect(card.name == nil)
        #expect(card.company == nil)
        #expect(card.jobTitle == nil)
        #expect(card.website == nil)
        #expect(card.address == nil)
        #expect(card.phones.isEmpty)
        #expect(card.emails.isEmpty)
        #expect(card.tags.isEmpty)
        #expect(card.notes.isEmpty)
        #expect(card.createdAt <= Date())
        #expect(card.updatedAt <= Date())
    }

    // MARK: - Spec §BusinessCard: required image references

    @Test("required image references are stored as deterministic String tokens")
    func requiredImageReferencesAreStored() throws {
        let card = BusinessCard(
            originalImageReference: "card-001-original",
            processedImageReference: "card-001-processed"
        )
        #expect(card.originalImageReference == "card-001-original")
        #expect(card.processedImageReference == "card-001-processed")
    }

    // MARK: - Spec §Missing-field rule

    @Test("card-004 shape: only name and one mobile phone; all other fields nil/empty")
    func card004ShapePreservesMissingFields() throws {
        let card = BusinessCard(
            originalImageReference: "card-004-original",
            processedImageReference: "card-004-processed",
            name: "张伟",
            phones: [PhoneNumber(kind: .mobile, value: "+86 138 0013 8000")]
        )
        #expect(card.originalImageReference == "card-004-original")
        #expect(card.processedImageReference == "card-004-processed")
        #expect(card.name == "张伟")
        #expect(card.company == nil)
        #expect(card.jobTitle == nil)
        #expect(card.website == nil)
        #expect(card.address == nil)
        #expect(card.emails.isEmpty)
        #expect(card.phones.count == 1)
        #expect(card.phones.first?.kind == .mobile)
        // Spec §Missing-field rule: do not fabricate.
        #expect(card.phones.first?.kind != .fax)
        #expect(card.rawOCRText == nil)
    }

    @Test("card-002 shape: website is nil and must not be fabricated")
    func card002ShapeWebsiteIsNil() throws {
        let card = BusinessCard(
            originalImageReference: "card-002-original",
            processedImageReference: "card-002-processed",
            name: "李娜",
            company: "上海智云科技有限公司",
            jobTitle: "市场总监 | Marketing Director",
            website: nil,
            phones: [
                PhoneNumber(kind: .mobile, value: "+86 139 1234 5678"),
                PhoneNumber(kind: .office, value: "+86 21 6888 2468"),
            ],
            emails: ["lina.li@zhiyuntech.com"]
        )
        #expect(card.website == nil)
        #expect(card.name == "李娜")
        #expect(card.phones.count == 2)
    }

    // MARK: - Spec §Multi-value observation

    @Test("card-001 shape: multiple phones of distinct kinds are preserved")
    func card001ShapePreservesMultiplePhones() throws {
        let card = BusinessCard(
            originalImageReference: "card-001-original",
            processedImageReference: "card-001-processed",
            name: "张伟",
            company: "上海智云科技有限公司",
            jobTitle: "产品总监 | Product Director",
            website: "www.zhiyuntech.com",
            address: "上海市浦东新区世纪大道100号 200120",
            phones: [
                PhoneNumber(kind: .mobile, value: "+86 138 0013 8000"),
                PhoneNumber(kind: .office, value: "+86 21 5555 1234"),
            ],
            emails: ["wei.zhang@zhiyuntech.com"]
        )
        #expect(card.originalImageReference == "card-001-original")
        #expect(card.processedImageReference == "card-001-processed")
        #expect(card.phones.count == 2)
        #expect(card.phones(of: .mobile).count == 1)
        #expect(card.phones(of: .office).count == 1)
        #expect(card.phones(of: .fax).isEmpty)
        #expect(card.emails == ["wei.zhang@zhiyuntech.com"])
    }

    @Test("card-011 shape: mobile + office + fax all classified by kind")
    func card011ShapeClassifiesThreePhoneKinds() throws {
        let card = BusinessCard(
            originalImageReference: "card-011-original",
            processedImageReference: "card-011-processed",
            name: "孙悦",
            company: "宁波启辰精工有限公司",
            jobTitle: "客户成功经理 | Customer Success Manager",
            phones: [
                PhoneNumber(kind: .mobile, value: "+86 158 5740 6621"),
                PhoneNumber(kind: .office, value: "+86 574 8790 3321"),
                PhoneNumber(kind: .fax, value: "+86 574 8790 3329"),
            ],
            emails: ["yue.sun@qichenprecision.com"]
        )
        #expect(card.phones.count == 3)
        #expect(card.phones(of: .mobile).count == 1)
        #expect(card.phones(of: .office).count == 1)
        #expect(card.phones(of: .fax).count == 1)
        #expect(card.firstPhone(of: .fax)?.value == "+86 574 8790 3329")
    }

    @Test("multiple phones of the same kind are all preserved (no collapse)")
    func multiplePhonesOfSameKindArePreserved() throws {
        let card = BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            phones: [
                PhoneNumber(kind: .mobile, value: "111"),
                PhoneNumber(kind: .mobile, value: "222"), // same kind, second number
            ]
        )
        #expect(card.phones(of: .mobile).count == 2)
        #expect(card.firstPhone(of: .mobile)?.value == "111")
    }

    // MARK: - Revision 7: rawOCRText default nil

    @Test("rawOCRText defaults to nil when no OCR pipeline exists")
    func rawOCRTextDefaultsToNil() throws {
        let card = BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed"
        )
        #expect(card.rawOCRText == nil)
    }

    // MARK: - Collections default empty

    @Test("tags and notes default to empty collections, not nil")
    func tagsAndNotesDefaultEmpty() throws {
        let card = BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed"
        )
        #expect(card.tags == [])
        #expect(card.notes == [])
    }

    @Test("tags and notes can be populated")
    func tagsAndNotesCanBePopulated() throws {
        let tag = CardTag(name: "VIP")
        let note = CardNote(text: "Saved at conference")
        let card = BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            tags: [tag],
            notes: [note]
        )
        #expect(card.tags.count == 1)
        #expect(card.tags.first?.name == "VIP")
        #expect(card.notes.count == 1)
        #expect(card.notes.first?.text == "Saved at conference")
        #expect(card.notes.first?.createdAt != nil)
    }

    // MARK: - Identity / equality

    @Test("two cards with same id and same content are equal")
    func sameIdAndContentAreEqual() throws {
        let id = UUID()
        let stamp = Date()
        let a = BusinessCard(
            id: id,
            originalImageReference: "card-001-original",
            processedImageReference: "card-001-processed",
            name: "张伟",
            createdAt: stamp,
            updatedAt: stamp
        )
        let b = BusinessCard(
            id: id,
            originalImageReference: "card-001-original",
            processedImageReference: "card-001-processed",
            name: "张伟",
            createdAt: stamp,
            updatedAt: stamp
        )
        #expect(a == b)
    }

    @Test("two cards with different ids are not equal")
    func differentIdsAreNotEqual() throws {
        let a = BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            name: "张伟"
        )
        let b = BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            name: "张伟"
        )
        #expect(a != b)
    }

    // MARK: - Accessor edge cases

    @Test("firstPhone returns nil when no phones of kind")
    func firstPhoneReturnsNilWhenEmpty() throws {
        let card = BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed"
        )
        #expect(card.firstPhone(of: .mobile) == nil)
        #expect(card.phones(of: .fax).isEmpty)
    }

    @Test("updatedAt can be advanced independently of createdAt")
    func updatedAtIndependentFromCreatedAt() throws {
        let created = Date(timeIntervalSince1970: 1_000_000_000)
        let updated = Date(timeIntervalSince1970: 2_000_000_000)
        let card = BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            createdAt: created,
            updatedAt: updated
        )
        #expect(card.createdAt == created)
        #expect(card.updatedAt == updated)
        #expect(card.updatedAt > card.createdAt)
    }
}
