//
//  CardFieldExtractorTests.swift
//  SimCamCardTests
//
//  Week 4 Increment 1 — parser-only deterministic fixture tests for
//  structured field extraction (T08/T09/T10 core).
//
//  These tests feed SYNTHETIC raw OCR lines directly — no Vision, no
//  images — so classification rules are asserted independently of OCR
//  probability. Real Vision → extraction is covered by
//  StructuredExtractionDatasetSmokeTests.
//

import Foundation
import Testing
@testable import SimCamCard

@Suite("Card field extractor — deterministic fixtures")
struct CardFieldExtractorTests {

    // MARK: - Helpers

    private static func makeOCRResult(_ lines: [String]) -> CardOCRResult {
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
        return CardOCRResult(
            cropResult: crop,
            lines: lines.map { OCRLine(text: $0, confidence: 1.0) }
        )
    }

    private func extract(_ lines: [String]) -> StructuredRecognitionResult {
        CardFieldExtractor().extract(from: Self.makeOCRResult(lines))
    }

    private func phoneValues(_ fields: StructuredCardFields, _ kind: PhoneNumber.Kind) -> [String] {
        fields.phones(of: kind).map(\.value)
    }

    // MARK: - 1. Labelled bilingual standard card (fixed 001-style fixture)

    @Test("1. labelled bilingual standard card yields canonical fields")
    func labelledBilingualStandardCard() {
        let fields = extract([
            "上海智云科技有限公司",
            "Shanghai Zhiyun Tech Co., Ltd.",
            "张伟",
            "Wei Zhang",
            "产品总监 | Product Director",
            "手机 Mobile：+86 138 0013 8000",
            "电话 Tel：+86 21 5555 1234",
            "邮箱 Email：wei.zhang@zhiyuntech.com",
            "网址 Web：www.zhiyuntech.com",
            "地址 Address：上海市浦东新区世纪大道100号 200120"
        ]).fields

        #expect(fields.name == "张伟")
        #expect(fields.company == "上海智云科技有限公司")
        #expect(fields.jobTitle == "产品总监 | Product Director")
        #expect(phoneValues(fields, .mobile) == ["+86 138 0013 8000"])
        #expect(phoneValues(fields, .office) == ["+86 21 5555 1234"])
        #expect(fields.phones(of: .fax).isEmpty)
        #expect(fields.emails == ["wei.zhang@zhiyuntech.com"])
        #expect(fields.website == "www.zhiyuntech.com")
        #expect(fields.address == "上海市浦东新区世纪大道100号 200120")
        #expect(fields.unclassifiedText == [
            "Shanghai Zhiyun Tech Co., Ltd.",
            "Wei Zhang"
        ])
    }

    // MARK: - 2. Email extraction (including OCR-garbled label, co.uk, order)

    @Test("2. email tokens classify despite garbled label; order and co.uk preserved")
    func emailExtraction() {
        let fields = extract([
            "邮稍 Email: wei.zhang@zhiyuntech.com",
            "E-mail: first.last@example.co.uk"
        ]).fields

        #expect(fields.emails == [
            "wei.zhang@zhiyuntech.com",
            "first.last@example.co.uk"
        ])
    }

    // MARK: - 3. Website extraction

    @Test("3. www and http(s) website tokens classify; first token wins")
    func websiteExtraction() {
        let www = extract(["网址 Web：www.example.com"]).fields
        #expect(www.website == "www.example.com")

        let https = extract(["https://example.com/path"]).fields
        #expect(https.website == "https://example.com/path")

        let http = extract(["http://example.org"]).fields
        #expect(http.website == "http://example.org")

        let ordered = extract(["www.example.com", "https://example.org"]).fields
        #expect(ordered.website == "www.example.com")
    }

    // MARK: - 4. Website absent

    @Test("4. card without website token keeps website nil")
    func websiteAbsent() {
        let fields = extract(["李娜", "lina.li@zhiyuntech.com"]).fields
        #expect(fields.website == nil)
    }

    // MARK: - 5. Mobile label family

    @Test("5. mobile label family (手机/移动/Mobile) classifies .mobile")
    func mobileLabel() {
        let fields1 = extract(["手机：138 0013 8000"]).fields
        #expect(phoneValues(fields1, .mobile) == ["138 0013 8000"])

        let fields2 = extract(["移动 Mobile: +86 139 1234 5678"]).fields
        #expect(phoneValues(fields2, .mobile) == ["+86 139 1234 5678"])
    }

    // MARK: - 6. Office label family

    @Test("6. office label family (电话/座机/Tel/Phone) classifies .office")
    func officeLabel() {
        let fields1 = extract(["电话 Tel：+86 21 5555 1234"]).fields
        #expect(phoneValues(fields1, .office) == ["+86 21 5555 1234"])

        let fields2 = extract(["座机：021-6888-2468"]).fields
        #expect(phoneValues(fields2, .office) == ["021-6888-2468"])
    }

    // MARK: - 7. Fax label family

    @Test("7. fax label family (传真/Fax/F) classifies .fax")
    func faxLabel() {
        let fields1 = extract(["传真 Fax：+86 21 5666 7799"]).fields
        #expect(phoneValues(fields1, .fax) == ["+86 21 5666 7799"])

        let fields2 = extract(["F: 021-5666-7799"]).fields
        #expect(phoneValues(fields2, .fax) == ["021-5666-7799"])
    }

    // MARK: - 8. Multiple phones preserve all values

    @Test("8. multiple mobile/office/fax values all preserved in encounter order")
    func multiplePhones() {
        let fields = extract([
            "Mobile: +86 136 8888 1024",
            "Mobile: +86 137 0000 0002",
            "Tel: +86 21 5666 7788",
            "Fax: +86 21 5666 7799"
        ]).fields

        #expect(phoneValues(fields, .mobile) == [
            "+86 136 8888 1024",
            "+86 137 0000 0002"
        ])
        #expect(phoneValues(fields, .office) == ["+86 21 5666 7788"])
        #expect(phoneValues(fields, .fax) == ["+86 21 5666 7799"])
        #expect(fields.phones.map(\.value) == [
            "+86 136 8888 1024",
            "+86 137 0000 0002",
            "+86 21 5666 7788",
            "+86 21 5666 7799"
        ])
    }

    // MARK: - 9. Duplicate phone dedupe

    @Test("9. duplicate phone values (same kind + digits) dedupe, first spelling kept")
    func duplicatePhoneDedupe() {
        let fields = extract([
            "Mobile: +86 138 0013 8000",
            "手机：+8613800138000"
        ]).fields

        #expect(fields.phones.count == 1)
        #expect(phoneValues(fields, .mobile) == ["+86 138 0013 8000"])
    }

    // MARK: - 10. Company classification

    @Test("10. company suffix/keyword classifies company (native preferred)")
    func companyClassification() {
        let cn = extract(["杭州远帆医疗科技有限公司"]).fields
        #expect(cn.company == "杭州远帆医疗科技有限公司")

        let en = extract(["Green Aurora Studio"]).fields
        #expect(en.company == "Green Aurora Studio")
    }

    // MARK: - 11. Job-title classification

    @Test("11. title keyword classifies job title, including bilingual single line")
    func jobTitleClassification() {
        let cn = extract(["陈晨", "商务拓展经理"]).fields
        #expect(cn.jobTitle == "商务拓展经理")

        let bilingual = extract(["产品总监 | Product Director"]).fields
        #expect(bilingual.jobTitle == "产品总监 | Product Director")

        let en = extract(["Kevin Park", "Solutions Architect"]).fields
        #expect(en.jobTitle == "Solutions Architect")
    }

    // MARK: - 12. Canonical name

    @Test("12. short person-like remaining line becomes canonical name")
    func canonicalName() {
        let fields = extract(["上海智云科技有限公司", "陈晨", "商务拓展经理"]).fields
        #expect(fields.name == "陈晨")
        #expect(fields.company == "上海智云科技有限公司")
        #expect(fields.jobTitle == "商务拓展经理")
    }

    // MARK: - 13. Bilingual name behavior

    @Test("13. bilingual card keeps native name; latin counterpart stays unclassified")
    func bilingualName() {
        let fields = extract(["张伟", "Wei Zhang"]).fields
        #expect(fields.name == "张伟")
        #expect(fields.unclassifiedText == ["Wei Zhang"])

        // Same-line bilingual form: CJK prefix is the canonical name.
        let inline = extract(["何嘉怡 Jiayi He"]).fields
        #expect(inline.name == "何嘉怡")
        #expect(inline.unclassifiedText == ["何嘉怡 Jiayi He"])
    }

    // MARK: - 14. Bilingual company behavior

    @Test("14. bilingual card keeps native company; english counterpart unclassified")
    func bilingualCompany() {
        let fields = extract([
            "上海智云科技有限公司",
            "Shanghai Zhiyun Tech Co., Ltd."
        ]).fields
        #expect(fields.company == "上海智云科技有限公司")
        #expect(fields.unclassifiedText == ["Shanghai Zhiyun Tech Co., Ltd."])
    }

    // MARK: - 15. Address label

    @Test("15. labelled address strips label and joins deterministic continuations")
    func addressLabel() {
        let fields = extract([
            "Address: 88 Market Street, Suite 920",
            "San Francisco, CA 94105"
        ]).fields

        #expect(fields.address == "88 Market Street, Suite 920 San Francisco, CA 94105")
        // Postal/short digit runs must not become phone numbers.
        #expect(fields.phones.isEmpty)
    }

    // MARK: - 16. Empty OCR → empty fields

    @Test("16. empty OCR lines produce an all-empty structured result without error")
    func emptyOCREmptyFields() {
        let result = extract([])
        #expect(result.fields.name == nil)
        #expect(result.fields.company == nil)
        #expect(result.fields.jobTitle == nil)
        #expect(result.fields.phones.isEmpty)
        #expect(result.fields.emails.isEmpty)
        #expect(result.fields.website == nil)
        #expect(result.fields.address == nil)
        #expect(result.fields.unclassifiedText.isEmpty)
        #expect(result.ocrResult.rawText == "")
    }

    // MARK: - 17. Unlabelled phone → .other

    @Test("17. unlabelled non-Chinese-mobile number classifies .other")
    func unlabelledPhoneOther() {
        let fields = extract(["Kevin Park", "+1 (415) 555-0184"]).fields
        #expect(fields.phones.count == 1)
        #expect(fields.phones.first?.kind == .other)
        #expect(fields.phones.first?.value == "+1 (415) 555-0184")
        #expect(fields.name == "Kevin Park")
    }

    @Test("17b. unlabelled +86 Chinese mobile form classifies .mobile (card-004 baseline)")
    func unlabelledChineseMobile() {
        let fields = extract(["张伟", "+86 138 0013 8000"]).fields
        #expect(phoneValues(fields, .mobile) == ["+86 138 0013 8000"])
        #expect(fields.phones(of: .other).isEmpty)
    }

    // MARK: - 18. No email-domain → website fabrication

    @Test("18. email domain is never fabricated into a website (T09 card-002 rule)")
    func noWebsiteFabricationFromEmail() {
        let fields = extract([
            "李娜",
            "lina.li@zhiyuntech.com",
            "手机 Mobile：+86 139 1234 5678"
        ]).fields

        #expect(fields.website == nil)
        #expect(fields.emails == ["lina.li@zhiyuntech.com"])
        #expect(phoneValues(fields, .mobile) == ["+86 139 1234 5678"])
    }

    // MARK: - 19. Raw OCR result remains unchanged

    @Test("19. extraction preserves the carried raw OCR result exactly")
    func rawOCRPreserved() {
        let raw = Self.makeOCRResult([
            "张伟",
            "邮稍 Email: wei.zhang@zhiyuntech.com",
            "手机 Mobile：+86 138 0013 8000"
        ])
        let result = CardFieldExtractor().extract(from: raw)

        #expect(result.ocrResult == raw)
        #expect(result.ocrResult.rawText == raw.rawText)
        #expect(result.ocrResult.rawText ==
                "张伟\n邮稍 Email: wei.zhang@zhiyuntech.com\n手机 Mobile：+86 138 0013 8000")
        // The OCR mis-read is carried verbatim, never corrected.
        #expect(result.ocrResult.rawText.contains("邮稍"))
        #expect(!result.ocrResult.rawText.contains("邮箱"))
    }

    // MARK: - 20. Deterministic repeat extraction

    @Test("20. repeated extraction of identical raw lines is value-equal")
    func deterministicRepeat() {
        let raw = Self.makeOCRResult([
            "上海智云科技有限公司",
            "张伟",
            "产品总监 | Product Director",
            "手机 Mobile：+86 138 0013 8000",
            "电话 Tel：+86 21 5555 1234",
            "传真 Fax：+86 21 5666 7799",
            "邮箱 Email：wei.zhang@zhiyuntech.com"
        ])
        let extractor = CardFieldExtractor()
        let first = extractor.extract(from: raw)
        let second = extractor.extract(from: raw)
        #expect(first == second)
    }
}
