//
//  RecognitionDraftTests.swift
//  SimCamCardTests
//
//  Week 4 Increment 3 — RecognitionDraft value tests (T11 manual
//  correction intermediate).
//
//  These are pure value-type tests: the draft is initialized from a
//  synthetic StructuredRecognitionResult (no Vision, no camera, no
//  ViewModel). They lock the three-layer separation:
//
//    raw OCR / structured source (immutable)  vs  edited draft strings
//
//  plus the correctedFields blank normalization, phone kind
//  preservation, email ordering and the hasChanges semantics.
//

import Foundation
import Testing
@testable import SimCamCard

@Suite("Recognition draft — T11 manual correction intermediate")
struct RecognitionDraftTests {

    // MARK: - Fixtures

    private static let mobileID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private static let officeID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    private static func makeResult(
        fields: StructuredCardFields,
        rawLines: [String] = ["张伟", "手机 Mobile：+86 138 0013 8000"]
    ) -> StructuredRecognitionResult {
        let photo = CapturedPhoto(data: Data([0x01, 0x02, 0x03]))
        let region = CardRegion(
            topLeft: NormalizedPoint(x: 0.1, y: 0.1),
            topRight: NormalizedPoint(x: 0.9, y: 0.1),
            bottomRight: NormalizedPoint(x: 0.9, y: 0.9),
            bottomLeft: NormalizedPoint(x: 0.1, y: 0.9),
            sourcePixelWidth: 100,
            sourcePixelHeight: 100
        )
        let crop = CardCropResult(
            original: photo,
            confirmedRegion: region,
            processedImageData: Data(),
            processedPixelWidth: 1,
            processedPixelHeight: 1
        )
        let ocr = CardOCRResult(
            cropResult: crop,
            lines: rawLines.map { OCRLine(text: $0, confidence: 1.0) }
        )
        return StructuredRecognitionResult(ocrResult: ocr, fields: fields)
    }

    private static func card001Fields() -> StructuredCardFields {
        StructuredCardFields(
            name: "张伟",
            company: "上海智云科技有限公司",
            jobTitle: "产品总监 | Product Director",
            phones: [
                PhoneNumber(id: mobileID, kind: .mobile, value: "+86 138 0013 8000"),
                PhoneNumber(id: officeID, kind: .office, value: "+86 21 5555 1234"),
            ],
            emails: ["wei.zhang@zhiyuntech.com"],
            website: "www.zhiyuntech.com",
            address: "上海市浦东新区世纪大道100号 200120",
            unclassifiedText: ["Wei Zhang", "Shanghai Zhiyun Tech Co., Ltd."]
        )
    }

    // MARK: - structured → draft mapping

    @Test("draft initialization preserves every structured value")
    func draftMapsStructuredValues() {
        let result = Self.makeResult(fields: Self.card001Fields())
        let draft = RecognitionDraft(source: result)

        #expect(draft.name == "张伟")
        #expect(draft.company == "上海智云科技有限公司")
        #expect(draft.jobTitle == "产品总监 | Product Director")
        #expect(draft.website == "www.zhiyuntech.com")
        #expect(draft.address == "上海市浦东新区世纪大道100号 200120")
        #expect(draft.phones.map(\.value) == ["+86 138 0013 8000", "+86 21 5555 1234"])
        #expect(draft.emails.map(\.value) == ["wei.zhang@zhiyuntech.com"])
    }

    @Test("nil structured scalars map to empty editable strings")
    func nilScalarsMapToEmptyStrings() {
        let fields = StructuredCardFields(
            phones: [PhoneNumber(id: Self.mobileID, kind: .mobile, value: "13800138000")]
        )
        let draft = RecognitionDraft(source: Self.makeResult(fields: fields))

        #expect(draft.name == "")
        #expect(draft.company == "")
        #expect(draft.jobTitle == "")
        #expect(draft.website == "")
        #expect(draft.address == "")
        #expect(draft.emails.isEmpty)
    }

    // MARK: - phone identity / kind

    @Test("phone rows keep stable positional ids, sourceIDs and kinds")
    func phoneRowsPreserveIdentityAndKind() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))

        #expect(draft.phones.map(\.id) == [0, 1])
        #expect(draft.phones[0].sourceID == Self.mobileID)
        #expect(draft.phones[0].kind == .mobile)
        #expect(draft.phones[1].sourceID == Self.officeID)
        #expect(draft.phones[1].kind == .office)
    }

    @Test("editing a phone value preserves its kind and sourceID")
    func editingPhoneKeepsKindAndSourceID() {
        var draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        draft.phones[0].value = "+86 138 0013 8001"

        let corrected = draft.correctedFields
        #expect(corrected.phones.count == 2)
        let mobile = corrected.phones(of: .mobile)
        #expect(mobile.map(\.value) == ["+86 138 0013 8001"])
        #expect(mobile.first?.id == Self.mobileID)
        #expect(corrected.phones(of: .office).map(\.value) == ["+86 21 5555 1234"])
    }

    // MARK: - email ordering

    @Test("multiple emails keep OCR encounter order and stable ids")
    func emailsKeepOrder() {
        let fields = StructuredCardFields(emails: [
            "a@example.com", "b@example.com", "c@example.com"
        ])
        let draft = RecognitionDraft(source: Self.makeResult(fields: fields))

        #expect(draft.emails.map(\.id) == [0, 1, 2])
        #expect(draft.correctedFields.emails == [
            "a@example.com", "b@example.com", "c@example.com"
        ])
    }

    @Test("editing one email updates only that email and keeps ordering")
    func editingOneEmailIsSurgical() {
        var draft = RecognitionDraft(source: Self.makeResult(
            fields: StructuredCardFields(emails: ["a@example.com", "b@example.com"])
        ))
        draft.emails[1].value = "edited@example.com"

        #expect(draft.correctedFields.emails == ["a@example.com", "edited@example.com"])
    }

    // MARK: - correctedFields

    @Test("unmodified draft projects fields equal to the source fields")
    func unmodifiedProjectionEqualsSource() {
        let result = Self.makeResult(fields: Self.card001Fields())
        let draft = RecognitionDraft(source: result)

        #expect(draft.correctedFields == result.fields)
    }

    @Test("scalar corrections project the edited values verbatim")
    func scalarCorrectionsProjectVerbatim() {
        var draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        draft.name = "张伟（修正）"
        draft.company = "上海智云科技"
        draft.jobTitle = "高级产品总监 | Senior Product Director"
        draft.website = "https://zhiyun.example.com"
        draft.address = "上海市浦东新区世纪大道200号"

        let corrected = draft.correctedFields
        #expect(corrected.name == "张伟（修正）")
        #expect(corrected.company == "上海智云科技")
        #expect(corrected.jobTitle == "高级产品总监 | Senior Product Director")
        #expect(corrected.website == "https://zhiyun.example.com")
        #expect(corrected.address == "上海市浦东新区世纪大道200号")
    }

    @Test("non-empty user content gets no semantic correction")
    func nonEmptyContentIsNotSemanticallyCorrected() {
        var draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        // Interior whitespace / odd casing preserved; surrounding space trimmed.
        draft.emails[0].value = "  Wei.Zhang@ZhiyunTech.COM  "
        draft.phones[0].value = "  +86 138 0013 8000 ext. 9 "

        let corrected = draft.correctedFields
        #expect(corrected.emails == ["Wei.Zhang@ZhiyunTech.COM"])
        #expect(corrected.phones(of: .mobile).map(\.value) == ["+86 138 0013 8000 ext. 9"])
    }

    // MARK: - blank normalization

    @Test("blank scalar strings normalize to nil")
    func blankScalarsNormalizeToNil() {
        var draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        draft.name = "   "
        draft.company = "\n\t"
        draft.jobTitle = ""
        draft.website = "  "
        draft.address = ""

        let corrected = draft.correctedFields
        #expect(corrected.name == nil)
        #expect(corrected.company == nil)
        #expect(corrected.jobTitle == nil)
        #expect(corrected.website == nil)
        #expect(corrected.address == nil)
    }

    @Test("blank phone and email values are dropped from corrected collections")
    func blankPhoneAndEmailAreDropped() {
        var draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        draft.phones[0].value = "   "
        draft.phones[1].value = ""
        draft.emails[0].value = "\t\n"

        let corrected = draft.correctedFields
        #expect(corrected.phones.isEmpty)
        #expect(corrected.emails.isEmpty)
    }

    @Test("one blank phone is dropped while the other survives with its kind")
    func mixedBlankPhones() {
        var draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        draft.phones[0].value = ""

        let corrected = draft.correctedFields
        #expect(corrected.phones.count == 1)
        #expect(corrected.phones.first?.kind == .office)
        #expect(corrected.phones.first?.value == "+86 21 5555 1234")
    }

    @Test("unclassifiedText is carried through unchanged")
    func unclassifiedTextPreserved() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        #expect(draft.correctedFields.unclassifiedText == [
            "Wei Zhang", "Shanghai Zhiyun Tech Co., Ltd."
        ])
    }

    // MARK: - source preservation

    @Test("editing the draft does not mutate the source structured fields")
    func sourceFieldsRemainImmutable() {
        let result = Self.makeResult(fields: Self.card001Fields())
        var draft = RecognitionDraft(source: result)
        draft.name = "张伟（修正）"
        draft.company = "上海智云科技"
        draft.phones[0].value = "+86 138 0013 8001"
        draft.emails[0].value = "other@example.com"
        draft.website = ""
        draft.address = "其他地址"

        #expect(draft.source.fields.name == "张伟")
        #expect(draft.source.fields.company == "上海智云科技有限公司")
        #expect(draft.source.fields.phones.map(\.value) == [
            "+86 138 0013 8000", "+86 21 5555 1234"
        ])
        #expect(draft.source.fields.emails == ["wei.zhang@zhiyuntech.com"])
        #expect(draft.source.fields.website == "www.zhiyuntech.com")
        #expect(draft.source.fields.address == "上海市浦东新区世纪大道100号 200120")
    }

    @Test("raw OCR stays reachable and unchanged through the draft")
    func rawOCRStaysPreserved() {
        let lines = ["张伟", "手机 Mobile：+86 138 0013 8000", "邮箱 Email：wei.zhang@zhiyuntech.com"]
        let result = Self.makeResult(fields: Self.card001Fields(), rawLines: lines)
        var draft = RecognitionDraft(source: result)
        draft.name = "完全不同的名字"

        #expect(draft.source.ocrResult.lines.map(\.text) == lines)
        #expect(draft.source.ocrResult.rawText == lines.joined(separator: "\n"))
        #expect(draft.source.ocrResult.rawText.contains("张伟"))
    }

    // MARK: - hasChanges

    @Test("a fresh draft reports no changes")
    func freshDraftHasNoChanges() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        #expect(!draft.hasChanges)
    }

    @Test("a corrected draft reports changes")
    func correctedDraftHasChanges() {
        var draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        draft.name = "张伟（修正）"
        #expect(draft.hasChanges)
    }

    @Test("whitespace-only edits are not changes after normalization")
    func whitespaceOnlyEditsAreNotChanges() {
        var draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        draft.name = "  张伟  "
        draft.company = "上海智云科技有限公司"
        #expect(!draft.hasChanges)
    }

    @Test("clearing an originally present field is a change")
    func clearingFieldIsAChange() {
        var draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        draft.website = ""
        #expect(draft.hasChanges)
    }

    // MARK: - Equatable / Sendable

    @Test("drafts with identical content are equal; edited drafts differ")
    func equatableBehavior() {
        let result = Self.makeResult(fields: Self.card001Fields())
        let draftA = RecognitionDraft(source: result)
        let draftB = RecognitionDraft(source: result)
        #expect(draftA == draftB)

        var edited = draftA
        edited.name = "张伟（修正）"
        #expect(edited != draftB)
    }

    @Test("draft is usable as a Sendable value across tasks")
    func sendableAcrossTasks() async {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        let result = await Task.detached {
            draft.correctedFields.name
        }.value
        #expect(result == "张伟")
    }
}
