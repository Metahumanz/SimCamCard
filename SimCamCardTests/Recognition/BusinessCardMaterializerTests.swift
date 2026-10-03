//
//  BusinessCardMaterializerTests.swift
//  SimCamCardTests
//
//  Week 4 Increment 4 (T12 calibration) — pure final-domain mapping
//  tests. The materializer is deterministic: card UUID, per-phone
//  final UUIDs, image references and timestamp are all injected, so
//  every outcome is directly assertable with fixed values and the same
//  complete inputs always produce the same BusinessCard.
//
//  Coverage: corrected fields, raw OCR preservation, image reference
//  pass-through, timestamps, injected final phone identity (kind +
//  value inherited; intermediate UUIDs never leak) and full
//  determinism.
//

import Foundation
import Testing
@testable import SimCamCard

@Suite("BusinessCard materializer — T12 final-domain mapping")
struct BusinessCardMaterializerTests {

    // MARK: - Fixed fixtures

    private static let mobileID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private static let officeID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    /// Final domain UUIDs injected by the orchestration layer — fixed
    /// and deliberately DISTINCT from the intermediate ids.
    private static let finalMobileID = UUID(uuidString: "11111111-1111-1111-1111-111111111101")!
    private static let finalOfficeID = UUID(uuidString: "11111111-1111-1111-1111-111111111102")!
    private static let cardID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEFFFF0000")!
    private static let timestamp = Date(timeIntervalSince1970: 1_791_000_000)

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
            processedImageData: Data([0xAA, 0xBB]),
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
            unclassifiedText: ["Wei Zhang"]
        )
    }

    /// All final identities/references/timestamps are fixed inputs.
    private static func materialize(_ draft: RecognitionDraft) -> BusinessCard {
        BusinessCardMaterializer.materialize(
            draft: draft,
            cardID: cardID,
            originalImageReference: "card-test-original",
            processedImageReference: "card-test-processed",
            timestamp: timestamp,
            finalPhoneIDs: [finalMobileID, finalOfficeID]
        )
    }

    // MARK: - Corrected fields

    @Test("corrected values land on the final card")
    func correctedValuesLandOnCard() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        var edited = draft
        edited.name = "张伟 修正"
        edited.website = "zhiyuntech.cn"

        let card = Self.materialize(edited)

        #expect(card.id == Self.cardID)
        #expect(card.name == "张伟 修正")
        #expect(card.company == "上海智云科技有限公司")
        #expect(card.jobTitle == "产品总监 | Product Director")
        #expect(card.website == "zhiyuntech.cn")
        #expect(card.address == "上海市浦东新区世纪大道100号 200120")
        #expect(card.emails == ["wei.zhang@zhiyuntech.com"])
    }

    @Test("blank corrections project to nil / dropped rows, never fabricated values")
    func blankCorrectionsProjectWithoutFabrication() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        var edited = draft
        edited.website = "   "
        edited.phones[1].value = ""

        // Only one phone survives blank-dropping, so one final ID aligns.
        let card = BusinessCardMaterializer.materialize(
            draft: edited,
            cardID: Self.cardID,
            originalImageReference: "o",
            processedImageReference: "p",
            timestamp: Self.timestamp,
            finalPhoneIDs: [Self.finalMobileID]
        )

        #expect(card.website == nil)
        #expect(card.phones.map(\.id) == [Self.finalMobileID])
        #expect(card.phones.map(\.value) == ["+86 138 0013 8000"])
        #expect(card.phones.map(\.kind) == [.mobile])
    }

    // MARK: - Raw OCR preservation

    @Test("rawOCRText is the original OCR rawText, untouched by corrections")
    func rawOCRTextIsPreserved() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        var edited = draft
        edited.name = "完全不同的名字"

        let card = Self.materialize(edited)

        #expect(card.rawOCRText == edited.source.ocrResult.rawText)
        #expect(card.rawOCRText?.contains("张伟") == true)
    }

    // MARK: - Image references

    @Test("image references pass through verbatim as real resolvable tokens")
    func imageReferencesPassThrough() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))

        let card = Self.materialize(draft)

        #expect(card.originalImageReference == "card-test-original")
        #expect(card.processedImageReference == "card-test-processed")
    }

    // MARK: - Timestamps

    @Test("createdAt and updatedAt both equal the provided timestamp")
    func timestampsComeFromTheProvidedDate() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))

        let card = Self.materialize(draft)

        #expect(card.createdAt == Self.timestamp)
        #expect(card.updatedAt == Self.timestamp)
    }

    // MARK: - Injected final phone identity

    @Test("final phones use the injected ids; only kind + value are inherited")
    func finalPhoneIDsAreInjectedAndValuesInherited() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        let intermediate = draft.correctedFields.phones
        #expect(intermediate.map(\.id) == [Self.mobileID, Self.officeID])

        let card = Self.materialize(draft)

        // The injected final ids are used verbatim, aligned by index.
        #expect(card.phones.map(\.id) == [Self.finalMobileID, Self.finalOfficeID])
        // Kind + value preserved.
        #expect(card.phones.map(\.kind) == intermediate.map(\.kind))
        #expect(card.phones.map(\.value) == intermediate.map(\.value))
        // None of the intermediate identities leaks onto the record.
        for final in card.phones {
            #expect(final.id != Self.mobileID)
            #expect(final.id != Self.officeID)
        }
    }

    // MARK: - Determinism

    @Test("identical complete inputs produce identical BusinessCards")
    func identicalInputsProduceIdenticalCards() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        let inputs: (UUID, String, String, Date, [UUID]) = (
            Self.cardID,
            "card-test-original",
            "card-test-processed",
            Self.timestamp,
            [Self.finalMobileID, Self.finalOfficeID]
        )

        let first = BusinessCardMaterializer.materialize(
            draft: draft,
            cardID: inputs.0,
            originalImageReference: inputs.1,
            processedImageReference: inputs.2,
            timestamp: inputs.3,
            finalPhoneIDs: inputs.4
        )
        let second = BusinessCardMaterializer.materialize(
            draft: draft,
            cardID: inputs.0,
            originalImageReference: inputs.1,
            processedImageReference: inputs.2,
            timestamp: inputs.3,
            finalPhoneIDs: inputs.4
        )

        // No implicit UUID()/Date() inside the materializer.
        #expect(first == second)
    }

    @Test("different injected phone ids change only phone identity, never values")
    func differentPhoneIDsChangeOnlyIdentity() {
        let draft = RecognitionDraft(source: Self.makeResult(fields: Self.card001Fields()))
        let otherMobile = UUID(uuidString: "22222222-2222-2222-2222-222222222201")!
        let otherOffice = UUID(uuidString: "22222222-2222-2222-2222-222222222202")!

        let card = BusinessCardMaterializer.materialize(
            draft: draft,
            cardID: Self.cardID,
            originalImageReference: "o",
            processedImageReference: "p",
            timestamp: Self.timestamp,
            finalPhoneIDs: [otherMobile, otherOffice]
        )

        #expect(card.phones.map(\.id) == [otherMobile, otherOffice])
        #expect(card.phones.map(\.kind) == [.mobile, .office])
        #expect(card.phones.map(\.value) == ["+86 138 0013 8000", "+86 21 5555 1234"])
    }
}
