//
//  BusinessCardEditDraftTests.swift
//  SimCamCardTests
//
//  Week 4 Increment 5 — BusinessCardEditDraft value tests (T14 existing-
//  card edit intermediate).
//
//  These are pure value-type tests: the draft is initialized from a
//  synthetic saved BusinessCard (no repository, no ViewModel). They lock:
//
//    saved BusinessCard (immutable source)  vs  edited draft strings
//
//  plus the existing-aggregate identity semantics (same card id, same
//  phone ids), metadata preservation (image refs / rawOCRText /
//  createdAt / tags / notes), blank normalization and hasChanges.
//

import Foundation
import Testing
@testable import SimCamCard

@Suite("BusinessCardEditDraft — T14 existing-card edit intermediate")
struct BusinessCardEditDraftTests {

    // MARK: - Fixtures

    private static let cardID = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!
    private static let mobileID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
    private static let officeID = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
    private static let tagID = UUID(uuidString: "C0000000-0000-0000-0000-000000000001")!
    private static let noteID = UUID(uuidString: "D0000000-0000-0000-0000-000000000001")!

    private static let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
    private static let originalUpdatedAt = Date(timeIntervalSince1970: 1_700_000_1000)
    private static let editTimestamp = Date(timeIntervalSince1970: 1_700_000_5000)

    private static func makeCard(
        name: String? = "张伟",
        company: String? = "上海智云科技有限公司",
        jobTitle: String? = "产品总监 | Product Director",
        website: String? = "www.zhiyuntech.com",
        address: String? = "上海市浦东新区世纪大道100号 200120",
        phones: [PhoneNumber]? = nil,
        emails: [String]? = ["wei.zhang@zhiyuntech.com"],
        rawOCRText: String? = "张伟 手机 Mobile：+86 138 0013 8000",
        tags: [CardTag]? = nil,
        notes: [CardNote]? = nil
    ) -> BusinessCard {
        BusinessCard(
            id: cardID,
            originalImageReference: "card-\(cardID.uuidString)-original",
            processedImageReference: "card-\(cardID.uuidString)-processed",
            rawOCRText: rawOCRText,
            name: name,
            company: company,
            jobTitle: jobTitle,
            website: website,
            address: address,
            phones: phones ?? [
                PhoneNumber(id: mobileID, kind: .mobile, value: "+86 138 0013 8000"),
                PhoneNumber(id: officeID, kind: .office, value: "+86 21 5555 1234"),
            ],
            emails: emails ?? [],
            tags: tags ?? [CardTag(id: tagID, name: "客户")],
            notes: notes ?? [CardNote(id: noteID, text: "展会上交换", createdAt: createdAt)],
            createdAt: createdAt,
            updatedAt: originalUpdatedAt
        )
    }

    // MARK: - BusinessCard → Draft mapping

    @Test("draft initialization maps every saved editable value")
    func draftMapsSavedValues() {
        let draft = BusinessCardEditDraft(source: Self.makeCard())

        #expect(draft.name == "张伟")
        #expect(draft.company == "上海智云科技有限公司")
        #expect(draft.jobTitle == "产品总监 | Product Director")
        #expect(draft.website == "www.zhiyuntech.com")
        #expect(draft.address == "上海市浦东新区世纪大道100号 200120")
        #expect(draft.phones.map(\.value) == ["+86 138 0013 8000", "+86 21 5555 1234"])
        #expect(draft.emails == ["wei.zhang@zhiyuntech.com"])
    }

    @Test("nil saved scalars map to empty editable strings")
    func nilScalarsMapToEmptyStrings() {
        let card = Self.makeCard(
            company: nil, jobTitle: nil, website: nil, address: nil,
            phones: [PhoneNumber(id: Self.mobileID, kind: .mobile, value: "13800138000")],
            emails: []
        )
        let draft = BusinessCardEditDraft(source: card)

        #expect(draft.name == "张伟")
        #expect(draft.company == "")
        #expect(draft.jobTitle == "")
        #expect(draft.website == "")
        #expect(draft.address == "")
        #expect(draft.emails.isEmpty)
    }

    @Test("draft phone rows keep the saved PhoneNumber ids and kinds")
    func phoneRowsKeepSavedIdentityAndKind() {
        let draft = BusinessCardEditDraft(source: Self.makeCard())

        #expect(draft.phones.map(\.id) == [Self.mobileID, Self.officeID])
        #expect(draft.phones.map(\.kind) == [.mobile, .office])
    }

    // MARK: - Projection: title correction (T14 acceptance)

    @Test("title correction projects the edited value verbatim")
    func titleCorrectionProjects() {
        var draft = BusinessCardEditDraft(source: Self.makeCard())
        draft.jobTitle = "高级产品总监 | Senior Product Director"

        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.jobTitle == "高级产品总监 | Senior Product Director")
    }

    @Test("scalar and email corrections project verbatim with surrounding trim only")
    func scalarAndEmailCorrectionsProject() {
        var draft = BusinessCardEditDraft(source: Self.makeCard())
        draft.name = "  张伟（已核） "
        draft.company = "上海智云科技"
        draft.website = "  https://zhiyun.example.com"
        draft.address = "上海市浦东新区世纪大道200号"
        draft.emails[0] = "  Wei.Zhang@ZhiyunTech.COM "

        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.name == "张伟（已核）")
        #expect(updated.company == "上海智云科技")
        #expect(updated.website == "https://zhiyun.example.com")
        #expect(updated.address == "上海市浦东新区世纪大道200号")
        #expect(updated.emails == ["Wei.Zhang@ZhiyunTech.COM"])
    }

    // MARK: - Blank normalization

    @Test("blank scalar edits project to nil")
    func blankScalarsProjectToNil() {
        var draft = BusinessCardEditDraft(source: Self.makeCard())
        draft.name = "   "
        draft.company = "\n\t"
        draft.jobTitle = ""
        draft.website = "  "
        draft.address = ""

        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.name == nil)
        #expect(updated.company == nil)
        #expect(updated.jobTitle == nil)
        #expect(updated.website == nil)
        #expect(updated.address == nil)
    }

    @Test("blank phone and email rows are omitted from the updated card")
    func blankPhoneAndEmailAreOmitted() {
        var draft = BusinessCardEditDraft(source: Self.makeCard())
        draft.phones[0].value = "   "
        draft.phones[1].value = ""
        draft.emails[0] = "\t\n"

        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.phones.isEmpty)
        #expect(updated.emails.isEmpty)
    }

    @Test("one blank phone is omitted while the other keeps kind, value and id")
    func mixedBlankPhones() {
        var draft = BusinessCardEditDraft(source: Self.makeCard())
        draft.phones[0].value = ""

        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.phones.count == 1)
        #expect(updated.phones.first?.id == Self.officeID)
        #expect(updated.phones.first?.kind == .office)
        #expect(updated.phones.first?.value == "+86 21 5555 1234")
    }

    // MARK: - Existing aggregate identity + metadata preservation

    @Test("phone value edit preserves the saved PhoneNumber id and kind")
    func phoneEditPreservesIDAndKind() {
        var draft = BusinessCardEditDraft(source: Self.makeCard())
        draft.phones[0].value = "+86 138 0013 9999"

        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        let mobile = updated.phones(of: .mobile)
        #expect(mobile.count == 1)
        #expect(mobile.first?.id == Self.mobileID)
        #expect(mobile.first?.kind == .mobile)
        #expect(mobile.first?.value == "+86 138 0013 9999")
        #expect(updated.phones.map(\.id) == [Self.mobileID, Self.officeID])
    }

    @Test("updated card keeps the same BusinessCard id")
    func cardIDIsPreserved() {
        let draft = BusinessCardEditDraft(source: Self.makeCard())
        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.id == Self.cardID)
    }

    @Test("image references are preserved unchanged")
    func imageReferencesArePreserved() {
        let source = Self.makeCard()
        let draft = BusinessCardEditDraft(source: source)
        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.originalImageReference == source.originalImageReference)
        #expect(updated.processedImageReference == source.processedImageReference)
    }

    @Test("rawOCRText is preserved unchanged")
    func rawOCRTextIsPreserved() {
        let source = Self.makeCard()
        var draft = BusinessCardEditDraft(source: source)
        draft.jobTitle = "高级产品总监 | Senior Product Director"
        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.rawOCRText == source.rawOCRText)
    }

    @Test("createdAt is preserved and updatedAt uses the supplied timestamp")
    func timestampsFollowTheRules() {
        let draft = BusinessCardEditDraft(source: Self.makeCard())
        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.createdAt == Self.createdAt)
        #expect(updated.updatedAt == Self.editTimestamp)
        #expect(updated.updatedAt != Self.originalUpdatedAt)
    }

    @Test("tags and notes are preserved unchanged")
    func tagsAndNotesArePreserved() {
        let source = Self.makeCard()
        var draft = BusinessCardEditDraft(source: source)
        draft.jobTitle = "高级产品总监 | Senior Product Director"
        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.tags == source.tags)
        #expect(updated.notes == source.notes)
        #expect(updated.tags.map(\.id) == [Self.tagID])
        #expect(updated.notes.map(\.id) == [Self.noteID])
    }

    @Test("nil rawOCRText stays nil through an edit")
    func nilRawOCRStaysNil() {
        let source = Self.makeCard(rawOCRText: nil)
        var draft = BusinessCardEditDraft(source: source)
        draft.name = "李明"
        let updated = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(updated.rawOCRText == nil)
    }

    // MARK: - Source immutability

    @Test("editing the draft never mutates the source BusinessCard")
    func sourceStaysUnchanged() {
        let source = Self.makeCard()
        var draft = BusinessCardEditDraft(source: source)
        draft.jobTitle = "高级产品总监 | Senior Product Director"
        draft.phones[0].value = "+86 138 0013 9999"
        draft.emails[0] = "edited@example.com"
        draft.name = "   "
        _ = draft.updatedCard(timestamp: Self.editTimestamp)

        #expect(source.jobTitle == "产品总监 | Product Director")
        #expect(source.phones.first?.value == "+86 138 0013 8000")
        #expect(source.emails == ["wei.zhang@zhiyuntech.com"])
        #expect(source.name == "张伟")
    }

    // MARK: - hasChanges

    @Test("hasChanges is false for a fresh untouched draft")
    func hasChangesFalseInitially() {
        let draft = BusinessCardEditDraft(source: Self.makeCard())
        #expect(draft.hasChanges == false)
    }

    @Test("hasChanges is true after a title correction")
    func hasChangesTrueAfterEdit() {
        var draft = BusinessCardEditDraft(source: Self.makeCard())
        draft.jobTitle = "高级产品总监 | Senior Product Director"
        #expect(draft.hasChanges)
    }

    @Test("hasChanges ignores updatedAt and sees whitespace-only edits as unchanged")
    func hasChangesIgnoresTimestampAndWhitespace() {
        // Same projection as source except updatedAt: not a user change.
        let draft = BusinessCardEditDraft(source: Self.makeCard())
        let repainted = draft.updatedCard(timestamp: Self.editTimestamp)
        #expect(repainted.updatedAt != Self.originalUpdatedAt)
        #expect(draft.hasChanges == false)

        var whitespaceDraft = BusinessCardEditDraft(source: Self.makeCard())
        whitespaceDraft.jobTitle = "  产品总监 | Product Director  "
        #expect(whitespaceDraft.hasChanges == false)
    }
}
