//
//  StructuredExtractionDatasetSmokeTests.swift
//  SimCamCardTests
//
//  Week 4 Increment 1 — REAL pipeline dataset smoke (T08/T09/T10):
//
//    dataset PNG
//    → CardCropProcessor.prepare / perspectiveCorrect (real Vision
//      detection + Core Image upright PNG)
//    → CardOCRProcessor.recognize (real Swift-native Vision OCR)
//    → CardFieldExtractor.extract (deterministic local parsing)
//
//  OCR is probabilistic, so assertions use stable ground-truth
//  semantic ANCHORS with TEST-ONLY normalization (compact contains /
//  digit contains), never exact transcript equality. Each failure
//  message prints BOTH the raw OCR text and the structured fields so
//  OCR limitations can be distinguished from parser defects:
//    - raw text missing the token  → OCR limitation
//    - raw text has it, fields don't → extraction defect
//
//  Dataset files are read in place and never modified. Ground truth is
//  used ONLY as test expected values; production code never reads it.
//

import Foundation
import Testing
@testable import SimCamCard

@Suite("Structured extraction dataset smoke")
struct StructuredExtractionDatasetSmokeTests {

    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Recognition/
        .deletingLastPathComponent()  // SimCamCardTests/
        .deletingLastPathComponent()  // <root>

    private static func compact(_ text: String) -> String {
        text.lowercased().filter { !$0.isWhitespace }
    }

    private static func digits(_ text: String) -> String {
        text.filter(\.isNumber)
    }

    /// TEST-ONLY anchor check on an optional field (keeps `#expect`
    /// macro expansion simple).
    private static func containsAnchor(_ field: String?, _ needle: String) -> Bool {
        compact(field ?? "").contains(needle)
    }

    /// Full in-place chain through crop → OCR → structured extraction.
    private func extractCard(_ imageName: String) async throws -> StructuredRecognitionResult {
        let url = Self.repoRoot.appending(path: "dataset/cards/\(imageName)")
        let data = try Data(contentsOf: url)
        let photo = CapturedPhoto(data: data)

        let cropProcessor = CardCropProcessor()
        let preparation = try await cropProcessor.prepare(photo)
        #expect(preparation.wasDetected, "detection must find the card in \(imageName)")

        let cropResult = try await cropProcessor.perspectiveCorrect(preparation.draft)
        let ocrResult = try await CardOCRProcessor().recognize(cropResult)
        return CardFieldExtractor().extract(from: ocrResult)
    }

    private func diagnostic(_ result: StructuredRecognitionResult) -> String {
        "\n--- rawText ---\n\(result.ocrResult.rawText)\n--- fields ---\n\(result.fields)"
    }

    // MARK: - card-001 — T08 standard bilingual extraction

    @Test("card-001 standard bilingual: structured anchors (T08)")
    func card001StructuredAnchors() async throws {
        let result = try await extractCard("card-001-standard-bilingual.png")
        let f = result.fields
        let note = diagnostic(result)

        #expect(Self.containsAnchor(f.name, "张伟"), "name anchor.\(note)")
        #expect(Self.containsAnchor(f.company, "智云"), "company anchor.\(note)")

        let mobileDigits = f.phones(of: .mobile).map { Self.digits($0.value) }.joined()
        let officeDigits = f.phones(of: .office).map { Self.digits($0.value) }.joined()
        #expect(mobileDigits.contains("13800138000"), "mobile classification.\(note)")
        #expect(officeDigits.contains("2155551234"), "office classification.\(note)")

        #expect(f.emails.joined().lowercased().contains("zhiyuntech"), "email anchor.\(note)")
        #expect(Self.containsAnchor(f.website, "zhiyuntech"), "website anchor.\(note)")
    }

    // MARK: - card-002 — T09 missing website must stay nil

    @Test("card-002 missing website: website stays nil (T09)")
    func card002WebsiteStaysNil() async throws {
        let result = try await extractCard("card-002-missing-website.png")
        let f = result.fields
        let note = diagnostic(result)

        #expect(f.website == nil, "T09: website must never be fabricated from email domain.\(note)")
        #expect(Self.containsAnchor(f.name, "李娜"), "name anchor.\(note)")
        #expect(Self.containsAnchor(f.company, "智云"), "company anchor.\(note)")

        let mobileDigits = f.phones(of: .mobile).map { Self.digits($0.value) }.joined()
        #expect(mobileDigits.contains("13912345678"), "mobile anchor.\(note)")
        #expect(f.emails.joined().lowercased().contains("zhiyuntech"), "email anchor.\(note)")
    }

    // MARK: - card-003 — T10 mobile / office / fax classification

    @Test("card-003 multiple phones: mobile/office/fax classified (T10)")
    func card003PhoneKinds() async throws {
        let result = try await extractCard("card-003-multiple-phones-fax.png")
        let f = result.fields
        let note = diagnostic(result)

        #expect(Self.containsAnchor(f.name, "陈晨"), "name anchor.\(note)")

        let mobileDigits = f.phones(of: .mobile).map { Self.digits($0.value) }.joined()
        let officeDigits = f.phones(of: .office).map { Self.digits($0.value) }.joined()
        let faxDigits = f.phones(of: .fax).map { Self.digits($0.value) }.joined()

        #expect(mobileDigits.contains("13688881024"), "mobile classification.\(note)")
        #expect(officeDigits.contains("2156667788"), "office classification.\(note)")
        #expect(faxDigits.contains("2156667799"), "fax classification.\(note)")
    }

    // MARK: - card-004 — minimal card: only name + mobile

    @Test("card-004 minimal card: name + mobile only")
    func card004MinimalNameMobile() async throws {
        let result = try await extractCard("card-004-minimal-name-mobile.png")
        let f = result.fields
        let note = diagnostic(result)

        #expect(Self.containsAnchor(f.name, "张伟"), "name anchor.\(note)")
        #expect(f.phones.count == 1, "exactly one phone.\(note)")
        #expect(f.phones.first?.kind == .mobile, "bare +86 mobile form.\(note)")
        let mobileDigits = Self.digits(f.phones.first?.value ?? "")
        #expect(mobileDigits.contains("13800138000"), "mobile digits anchor.\(note)")

        #expect(f.company == nil, "company must be nil.\(note)")
        #expect(f.jobTitle == nil, "jobTitle must be nil.\(note)")
        #expect(f.emails.isEmpty, "emails must be empty.\(note)")
        #expect(f.website == nil, "website must be nil.\(note)")
        #expect(f.address == nil, "address must be nil.\(note)")
    }
}
