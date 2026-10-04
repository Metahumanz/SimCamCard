//
//  BusinessCardSearchMatcherTests.swift
//  SimCamCardTests
//
//  Unit tests for the T15 deterministic search predicate (Swift Testing).
//
//  Spec sources:
//   - spec/reference-tests.md T15 Search (name, company, job title,
//     phone, email; black-box evidence covers name/company only)
//   - spec/page-inventory.md P08 Search Results
//
//  Test cards are built inline (not the DEBUG UI fixture) so this suite
//  is configuration-independent and can pin exact multi-phone /
//  multi-email / nil-field shapes.
//

import Testing
import Foundation
@testable import SimCamCard

@MainActor
@Suite("BusinessCardSearchMatcher")
struct BusinessCardSearchMatcherTests {

    // MARK: - Fixtures

    private let matcher = BusinessCardSearchMatcher()

    private func makeCard(
        name: String? = nil,
        company: String? = nil,
        jobTitle: String? = nil,
        phones: [PhoneNumber] = [],
        emails: [String] = []
    ) -> BusinessCard {
        BusinessCard(
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            name: name,
            company: company,
            jobTitle: jobTitle,
            phones: phones,
            emails: emails
        )
    }

    private func phone(_ idSuffix: String, _ value: String,
                       kind: PhoneNumber.Kind = .mobile) -> PhoneNumber {
        PhoneNumber(
            id: UUID(uuidString: "10000000-0000-0000-0000-\(idSuffix)")!,
            kind: kind,
            value: value
        )
    }

    // MARK: - Empty / whitespace query

    @Test("an empty query matches every card")
    func emptyQueryMatchesEveryCard() {
        let card = makeCard(name: "张伟")
        #expect(matcher.matches(card: card, query: ""))
        #expect(matcher.matches(card: BusinessCard(
            originalImageReference: "o", processedImageReference: "p"), query: ""))
    }

    @Test("a whitespace-only query matches every card")
    func whitespaceOnlyQueryMatchesEveryCard() {
        let card = makeCard(name: "张伟")
        #expect(matcher.matches(card: card, query: "   \n\t "))
    }

    // MARK: - Name

    @Test("a name exact match hits")
    func nameExactMatchHits() {
        let card = makeCard(name: "张伟")
        #expect(matcher.matches(card: card, query: "张伟"))
    }

    @Test("a name partial match hits")
    func namePartialMatchHits() {
        let card = makeCard(name: "欧阳修")
        #expect(matcher.matches(card: card, query: "阳"))
    }

    // MARK: - Company

    @Test("a company partial match hits")
    func companyPartialMatchHits() {
        let card = makeCard(company: "上海智云科技有限公司")
        #expect(matcher.matches(card: card, query: "智云"))
    }

    // MARK: - Job title

    @Test("a job-title Latin substring match hits")
    func jobTitleMatchHits() {
        let card = makeCard(jobTitle: "产品总监 | Product Director")
        #expect(matcher.matches(card: card, query: "Product Director"))
    }

    // MARK: - Phone

    @Test("a digits-only query matches a formatted stored phone")
    func digitsOnlyQueryMatchesFormattedPhone() {
        let card = makeCard(phones: [phone("000000000001", "+86 138 0013 8000")])
        #expect(matcher.matches(card: card, query: "13800138000"))
    }

    @Test("a formatted query matches a stored phone after normalization")
    func formattedQueryMatchesStoredPhone() {
        let card = makeCard(phones: [phone("000000000001", "+86 138 0013 8000")])
        #expect(matcher.matches(card: card, query: "+86 138 0013 8000"))
    }

    @Test("a digits substring matches any of several phones")
    func phoneMatchSearchesMultiplePhones() {
        let card = makeCard(phones: [
            phone("000000000001", "+86 138 0013 8000"),
            phone("000000000002", "+86 21 5555 1234", kind: .office),
        ])
        #expect(matcher.matches(card: card, query: "55551234"))
        #expect(matcher.matches(card: card, query: "862155551234"))
    }

    // MARK: - Email

    @Test("an email local-part substring hits")
    func emailPartialMatchHits() {
        let card = makeCard(emails: ["wei.zhang@zhiyuntech.com"])
        #expect(matcher.matches(card: card, query: "wei.zhang"))
    }

    @Test("an email match searches every stored email")
    func emailMatchSearchesMultipleEmails() {
        let card = makeCard(emails: [
            "wei.zhang@zhiyuntech.com",
            "backup@example.com",
        ])
        #expect(matcher.matches(card: card, query: "backup@example"))
    }

    // MARK: - Case insensitivity

    @Test("Latin text fields match case-insensitively")
    func latinFieldsAreCaseInsensitive() {
        let card = makeCard(
            name: "Wei Zhang",
            company: "Zhiyun Tech",
            jobTitle: "Product Director",
            emails: ["wei.zhang@zhiyuntech.com"]
        )
        #expect(matcher.matches(card: card, query: "wei zhang"))
        #expect(matcher.matches(card: card, query: "ZHIYUN"))
        #expect(matcher.matches(card: card, query: "product director"))
        #expect(matcher.matches(card: card, query: "WEI.ZHANG@ZHiyunTech.com"))
    }

    // MARK: - Non-match / missing fields

    @Test("a query appearing in no field does not match")
    func nonMatchingQueryMisses() {
        let card = makeCard(
            name: "张伟",
            company: "上海智云科技有限公司",
            jobTitle: "产品总监 | Product Director",
            phones: [phone("000000000001", "+86 138 0013 8000")],
            emails: ["wei.zhang@zhiyuntech.com"]
        )
        #expect(!matcher.matches(card: card, query: "李四"))
        #expect(!matcher.matches(card: card, query: "99999999"))
        #expect(!matcher.matches(card: card, query: "nobody@nowhere"))
    }

    @Test("nil fields never fabricate a match")
    func nilFieldsDoNotFabricateMatch() {
        let minimal = makeCard(name: "张伟")
        // Company / job-title / email queries must not hit a card that
        // simply lacks those fields (no empty-string fabrication).
        #expect(!matcher.matches(card: minimal, query: "智云"))
        #expect(!matcher.matches(card: minimal, query: "Product Director"))
        #expect(!matcher.matches(card: minimal, query: "@"))
        #expect(!matcher.matches(card: minimal, query: "13800138000"))
    }

    @Test("surrounding whitespace in the query is trimmed before matching")
    func queryIsTrimmedBeforeMatching() {
        let card = makeCard(name: "张伟")
        #expect(matcher.matches(card: card, query: "   张伟 \n"))
    }
}
