//
//  StructuredGroundTruthRegressionTests.swift
//  SimCamCardTests
//
//  Week 4 Increment 12 §28 — 34-card GT-level deterministic
//  structured-extraction regression.
//
//  SCOPE / HONESTY BOUNDARY (plan W4I12 §28):
//  This is a GT-LEVEL structured regression, NOT a real Vision OCR
//  integration. Ground-truth JSON contains field VALUES, not OCR
//  transcript lines, so the harness deterministically SYNTHESIZES the
//  OCR token lines a perfect recognizer would emit from each GT record
//  (bilingual labels for typed fields; bare lines for semantic fields)
//  and feeds them straight to the pure CardFieldExtractor. It measures
//  the deterministic parser/classifier only:
//
//    GT values → synthetic OCR lines → CardFieldExtractor → vs GT
//
//  It must never be quoted as "34 real Vision OCR successes". Real
//  Vision behavior over the PNG dataset is covered at anchor level by
//  StructuredExtractionDatasetSmokeTests (cards 001–004) and the
//  targeted real-pipeline gates.
//
//  Ground truth is read in place and never modified.
//
//  Reported summary (printed per run, also pinned by assertions):
//   - 34 total business cards
//   - exact full-match count
//   - known parser exceptions (pinned registry with reasons)
//   - missing-field false positives (GT absent → extracted present)
//   - multi-phone correctness (cards expected to carry ≥2 phones)
//  Plus the independent T20 non-card exception fixture (counted
//  separately, NEVER in business-card totals — plan §29).
//

import Foundation
import Testing
@testable import SimCamCard

@Suite("Structured extraction GT-level regression (34 cards)")
struct StructuredGroundTruthRegressionTests {

    // MARK: - GT model

    private struct GroundTruth: Decodable {
        let id: String
        let name: String?
        let nameLatin: String?
        let company: String?
        let companyLatin: String?
        let department: String?
        let jobTitle: String?
        let mobile: String?
        let phone: String?
        let fax: String?
        let email: String?
        let website: String?
        let address: String?
    }

    private struct NegativeFixture: Decodable {
        let id: String
        let observedBehavior: Behavior

        struct Behavior: Decodable {
            let recognitionErrorDialog: Bool
            let enteredEditCardScreen: Bool
            let name: String?
            let structuredContactFields: String
            let userCanReturnOrRetake: Bool
        }
    }

    // MARK: - Paths / stub crop

    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Recognition/
        .deletingLastPathComponent()  // SimCamCardTests/
        .deletingLastPathComponent()  // <root>

    private static let groundTruthDir = repoRoot
        .appending(path: "dataset/ground-truth")

    private static let negativeExpectedURL = repoRoot
        .appending(path: "dataset/exception-samples/t20-negative-001-expected.json")

    /// Content of the crop is irrelevant: the extractor only reads
    /// `lines`. A minimal valid CardCropResult is supplied for shape.
    private static let stubCrop = CardCropResult(
        original: CapturedPhoto(data: Data([0x89, 0x50, 0x4E, 0x47])),
        confirmedRegion: CardRegion(
            topLeft: NormalizedPoint(x: 0.1, y: 0.16),
            topRight: NormalizedPoint(x: 0.9, y: 0.16),
            bottomRight: NormalizedPoint(x: 0.9, y: 0.84),
            bottomLeft: NormalizedPoint(x: 0.1, y: 0.84),
            sourcePixelWidth: 600,
            sourcePixelHeight: 380
        ),
        processedImageData: Data([0x89, 0x50, 0x4E, 0x47]),
        processedPixelWidth: 420,
        processedPixelHeight: 260
    )

    // MARK: - Loading

    private static func loadAllGroundTruth() throws -> [GroundTruth] {
        let urls = (1...34).map {
            groundTruthDir.appending(path: String(format: "card-%03d.json", $0))
        }
        return try urls.map { url in
            try JSONDecoder().decode(GroundTruth.self, from: Data(contentsOf: url))
        }
    }

    // MARK: - Synthetic line construction
    //
    // Typed fields use the SAME bilingual label forms already proven by
    // the DEBUG OCR fixtures (手机 Mobile / 电话 Tel / 传真 Fax /
    // 邮箱 Email / 网址 Web / 地址 Address). Semantic fields are bare
    // lines in the order the synthetic bilingual cards print them
    // (company block → person → title). Address is emitted LAST so no
    // continuation-line heuristic can claim another field.

    private static func syntheticLines(for gt: GroundTruth) -> [String] {
        var lines: [String] = []
        if gt.company != nil {
            if let company = gt.company { lines.append(company) }
            if let companyLatin = gt.companyLatin { lines.append(companyLatin) }
        } else if let companyLatin = gt.companyLatin {
            lines.append(companyLatin)
        }
        if let name = gt.name { lines.append(name) }
        if let nameLatin = gt.nameLatin { lines.append(nameLatin) }
        if let department = gt.department { lines.append(department) }
        if let jobTitle = gt.jobTitle { lines.append(jobTitle) }
        if let mobile = gt.mobile { lines.append("手机 Mobile：\(mobile)") }
        if let phone = gt.phone { lines.append("电话 Tel：\(phone)") }
        if let fax = gt.fax { lines.append("传真 Fax：\(fax)") }
        if let email = gt.email { lines.append("邮箱 Email：\(email)") }
        if let website = gt.website { lines.append("网址 Web：\(website)") }
        if let address = gt.address { lines.append("地址 Address：\(address)") }
        return lines
    }

    private static func extract(_ lines: [String]) -> StructuredCardFields {
        let ocr = CardOCRResult(
            cropResult: stubCrop,
            lines: lines.map { OCRLine(text: $0, confidence: 1.0) }
        )
        return CardFieldExtractor().extract(from: ocr).fields
    }

    // MARK: - Normalization

    private static func compact(_ text: String?) -> String {
        (text ?? "").lowercased().filter { !$0.isWhitespace }
    }

    private static func digits(_ text: String?) -> String {
        (text ?? "").filter(\.isNumber)
    }

    /// Website GT may carry a scheme; the extractor keeps the printed
    /// token verbatim. Compare on scheme-stripped compact form.
    private static func compactWebsite(_ text: String?) -> String {
        var value = compact(text)
        if value.hasPrefix("https://") { value.removeFirst(8) }
        if value.hasPrefix("http://") { value.removeFirst(7) }
        return value
    }

    // MARK: - Per-card report

    private struct FieldMismatch: CustomStringConvertible {
        let field: String
        let expected: String
        let actual: String
        var description: String { "\(field): expected[\(expected)] actual[\(actual)]" }
    }

    private struct CardReport {
        let id: String
        let typedMismatches: [FieldMismatch]
        let semanticMismatches: [FieldMismatch]
        let expectedPhoneCount: Int
        let actualPhoneCount: Int

        var isExact: Bool { typedMismatches.isEmpty && semanticMismatches.isEmpty }
        var multiPhoneRelevant: Bool { expectedPhoneCount >= 2 }
        var multiPhoneCorrect: Bool {
            expectedPhoneCount == actualPhoneCount
                && typedMismatches.allSatisfy { !$0.field.hasPrefix("phone:") }
        }
    }

    private static func report(for gt: GroundTruth) -> CardReport {
        let f = extract(syntheticLines(for: gt))
        var typed: [FieldMismatch] = []
        var semantic: [FieldMismatch] = []

        func check(
            field: String,
            expected: String?,
            actual: String?,
            normalize: (String?) -> String,
            bucket: inout [FieldMismatch]
        ) {
            let e = normalize(expected)
            let a = normalize(actual)
            if e != a {
                bucket.append(FieldMismatch(
                    field: field,
                    expected: expected ?? "<nil>",
                    actual: actual ?? "<nil>"
                ))
            }
        }

        // ---- Typed layer: phones by kind ----
        let actualMobile = f.phones(of: .mobile).map(\.value)
        let actualOffice = f.phones(of: .office).map(\.value)
        let actualFax = f.phones(of: .fax).map(\.value)
        let actualOther = f.phones(of: .other).map(\.value)
        let expectedPhoneCount = [gt.mobile, gt.phone, gt.fax].compactMap { $0 }.count

        check(field: "phone:mobile", expected: gt.mobile,
              actual: actualMobile.first, normalize: digits, bucket: &typed)
        check(field: "phone:office", expected: gt.phone,
              actual: actualOffice.first, normalize: digits, bucket: &typed)
        check(field: "phone:fax", expected: gt.fax,
              actual: actualFax.first, normalize: digits, bucket: &typed)
        if !actualOther.isEmpty {
            typed.append(FieldMismatch(
                field: "phone:other",
                expected: "<none>",
                actual: actualOther.joined(separator: ",")
            ))
        }
        if actualMobile.count > 1 {
            typed.append(FieldMismatch(
                field: "phone:mobile-extra", expected: "≤1",
                actual: "\(actualMobile.count)"
            ))
        }
        if actualOffice.count > 1 {
            typed.append(FieldMismatch(
                field: "phone:office-extra", expected: "≤1",
                actual: "\(actualOffice.count)"
            ))
        }
        if actualFax.count > 1 {
            typed.append(FieldMismatch(
                field: "phone:fax-extra", expected: "≤1",
                actual: "\(actualFax.count)"
            ))
        }

        // ---- Typed layer: email / website / address ----
        let expectedEmail = gt.email?.lowercased()
        let actualEmail = f.emails.first?.lowercased()
        check(field: "email", expected: expectedEmail,
              actual: actualEmail, normalize: compact, bucket: &typed)
        if f.emails.count > 1 {
            typed.append(FieldMismatch(
                field: "email-extra", expected: "≤1",
                actual: "\(f.emails.count)"
            ))
        }
        check(field: "website", expected: gt.website,
              actual: f.website, normalize: compactWebsite, bucket: &typed)
        check(field: "address", expected: gt.address,
              actual: f.address, normalize: compact, bucket: &typed)

        // ---- Semantic layer: name / company / job title ----
        //
        // Accept the printed-language GT variant the parser chose (CJK
        // name vs its latin transliteration; CJK company vs latin
        // entity). The extractor returns ONE name/company, and the
        // frozen domain is single-valued.
        let nameOptions = [gt.name, gt.nameLatin].compactMap { $0 }.map(compact)
        if !nameOptions.contains(compact(f.name)) {
            semantic.append(FieldMismatch(
                field: "name",
                expected: [gt.name, gt.nameLatin].compactMap { $0 }.joined(separator: " / "),
                actual: f.name ?? "<nil>"
            ))
        }
        let companyOptions = [gt.company, gt.companyLatin].compactMap { $0 }.map(compact)
        if !companyOptions.contains(compact(f.company)) {
            semantic.append(FieldMismatch(
                field: "company",
                expected: [gt.company, gt.companyLatin].compactMap { $0 }.joined(separator: " / "),
                actual: f.company ?? "<nil>"
            ))
        }
        check(field: "jobTitle", expected: gt.jobTitle,
              actual: f.jobTitle, normalize: compact, bucket: &semantic)

        return CardReport(
            id: gt.id,
            typedMismatches: typed,
            semanticMismatches: semantic,
            expectedPhoneCount: expectedPhoneCount,
            actualPhoneCount: f.phones.count
        )
    }

    // MARK: - Pinned known parser exceptions (semantic layer only)
    //
    // The semantic Phase-B heuristics are CJK-layout oriented; GT cards
    // 005–034 deliberately cover english-only / CJK-vertical / multi
    // script layouts that exceed those heuristics. Every deviation
    // observed in the GT-level harness is pinned HERE with a reason so
    // the count cannot silently drift. Typed-layer classification has
    // no allowed exceptions. These are PARSER limitations on synthetic
    // GT-derived lines, not Vision OCR results.

    // Pinned from the first honest harness run (32/34 full exact).
    // Both deviations are the SAME class: the Phase-B job-title
    // heuristic recognizes CJK title lexemes and a latin keyword table
    // (Director|Manager|Engineer|Architect|Designer|Consultant|Lead|...),
    // but neither katakana transliterations nor "Researcher".
    private static let knownSemanticExceptions: [String: Set<String>] = [
        // マネージャー is a katakana title with no CJK/latin keyword.
        "card-019": ["jobTitle"],
        // "UX Researcher": Researcher is not in the latin title table.
        "card-030": ["jobTitle"],
    ]

    // MARK: - Tests

    @Test("§28 typed-layer classification is exact for all 34 GT cards (zero false positives)")
    func typedLayerExactAcross34Cards() throws {
        let cards = try Self.loadAllGroundTruth()
        #expect(cards.count == 34)

        var falsePositives = 0
        for gt in cards {
            let report = Self.report(for: gt)
            for mismatch in report.typedMismatches {
                if mismatch.expected == "<nil>" || mismatch.expected == "≤1" {
                    falsePositives += 1
                }
            }
            if !report.typedMismatches.isEmpty {
                Issue.record(
                    "\(gt.id) typed-layer mismatch: \(report.typedMismatches.map(\.description))"
                )
            }
        }
        #expect(falsePositives == 0,
                "GT-absent typed fields must never be fabricated (missing-field false positives).")
    }

    @Test("§28 semantic-layer deviations equal the pinned known-parser-exception registry")
    func semanticLayerMatchesPinnedExceptionRegistry() throws {
        let cards = try Self.loadAllGroundTruth()
        var observed: [String: Set<String>] = [:]
        for gt in cards {
            let report = Self.report(for: gt)
            if !report.semanticMismatches.isEmpty {
                observed[gt.id] = Set(report.semanticMismatches.map(\.field))
            }
        }

        let known = Self.knownSemanticExceptions
        let unexpected = observed.filter { known[$0.key] != $0.value }
        let stale = known.filter { observed[$0.key] != $0.value }
        #expect(unexpected.isEmpty,
                "Unpinned semantic parser exceptions: \(unexpected). Re-audit and pin with a reason, or fix the parser — do not edit GT.")
        #expect(stale.isEmpty,
                "Stale pinned exceptions no longer reproduced: \(stale). Remove them from the registry.")
    }

    @Test("§28 multi-phone cards keep exact phone count and mobile/office/fax kinds")
    func multiPhoneCardsCorrect() throws {
        let cards = try Self.loadAllGroundTruth()
        let multi = cards.map(Self.report(for:)).filter(\.multiPhoneRelevant)
        #expect(!multi.isEmpty, "Dataset must include multi-phone cards.")
        for report in multi where !report.multiPhoneCorrect {
            let detail = "\(report.id) multi-phone mismatch: expected "
                + "\(report.expectedPhoneCount), got \(report.actualPhoneCount); "
                + "\(report.typedMismatches.map(\.description))"
            Issue.record("\(detail)")
        }
    }

    @Test("§28 summary: prints exact-match and exception counts for the 34-card report")
    func summaryCounts() throws {
        let cards = try Self.loadAllGroundTruth()
        let reports = cards.map(Self.report(for:))
        let exact = reports.filter(\.isExact).count
        let typedExact = reports.filter { $0.typedMismatches.isEmpty }.count
        let exceptionCards = reports.filter { !$0.semanticMismatches.isEmpty }.map(\.id)
        let falsePositives = reports.flatMap(\.typedMismatches)
            .filter { $0.expected == "<nil>" || $0.expected == "≤1" }.count
        let multi = reports.filter(\.multiPhoneRelevant)
        let multiCorrect = multi.filter(\.multiPhoneCorrect).count

        print("""

        ============= W4I12 §28 GT-LEVEL STRUCTURED REGRESSION =============
        LEVEL: GT-derived synthetic OCR lines → CardFieldExtractor (NOT Vision)
        total business cards: \(reports.count)
        typed-layer exact (phones/email/web/address): \(typedExact)/\(reports.count)
        full exact (typed + name/company/title): \(exact)/\(reports.count)
        cards with pinned semantic parser exceptions: \(exceptionCards.count) -> \(exceptionCards.sorted())
        missing-field false positives (fabrications): \(falsePositives)
        multi-phone cards correct: \(multiCorrect)/\(multi.count)
        --------------------------------------------------------------------
        """)
        for report in reports where !report.isExact {
            let problems = (report.typedMismatches + report.semanticMismatches)
                .map(\.description).joined(separator: "; ")
            print("  \(report.id): \(problems)")
        }
        print("====================================================================")

        #expect(reports.count == 34)
        #expect(falsePositives == 0)
        #expect(multiCorrect == multi.count)
        // The summary must stay consistent with the pinned registry.
        #expect(Set(exceptionCards) == Set(Self.knownSemanticExceptions.keys))
    }

    // MARK: - §29 T20 non-card exception fixture (independent count)

    @Test("§29 T20 non-card fixture: zero canonical fields; counted independently of the 34")
    func t20NonCardFixtureYieldsEmptyStructuredFields() throws {
        let fixture = try JSONDecoder().decode(
            NegativeFixture.self,
            from: Data(contentsOf: Self.negativeExpectedURL)
        )
        #expect(fixture.id == "t20-negative-001")
        let expected = fixture.observedBehavior
        #expect(expected.structuredContactFields == "empty")
        #expect(expected.recognitionErrorDialog == false)
        #expect(expected.enteredEditCardScreen == true)
        #expect(expected.userCanReturnOrRetake == true)

        // A non-card image produces zero OCR lines → extractor output
        // must carry NO canonical field (the §27-B fixture path).
        let f = Self.extract([])
        #expect(f.name == nil)
        #expect(f.company == nil)
        #expect(f.jobTitle == nil)
        #expect(f.website == nil)
        #expect(f.address == nil)
        #expect(f.phones.isEmpty)
        #expect(f.emails.isEmpty)
    }
}
