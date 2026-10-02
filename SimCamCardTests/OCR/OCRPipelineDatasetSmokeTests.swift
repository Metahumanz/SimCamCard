//
//  OCRPipelineDatasetSmokeTests.swift
//  SimCamCardTests
//
//  End-to-end dataset smoke for the camera-less still pipeline
//  (Week 3 Increment 6 — T07):
//
//    dataset PNG
//    → CardCropProcessor.prepare (real decode + real Vision rectangle
//      detection)
//    → CardCropProcessor.perspectiveCorrect (real Core Image upright
//      PNG — never skipped)
//    → CardOCRProcessor.recognize (real Swift-native Vision text
//      recognition)
//    → preserved raw text
//
//  SMOKE tests, not transcript diffs: OCR is probabilistic, so
//  assertions use stable ground-truth ANCHORS with TEST-ONLY
//  normalization (lowercase + whitespace removal / digit extraction).
//  The production raw value itself is never normalized. No structured
//  field assertions (name/company parsing is Week 4).
//
//  Dataset files are read in place and never modified.
//

import Foundation
import Testing
@testable import SimCamCard

@Suite("OCR pipeline dataset smoke")
struct OCRPipelineDatasetSmokeTests {

    /// Repository root derived from this file's path:
    /// <root>/SimCamCardTests/OCR/OCRPipelineDatasetSmokeTests.swift
    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // OCR/
        .deletingLastPathComponent()  // SimCamCardTests/
        .deletingLastPathComponent()  // <root>

    /// TEST-ONLY normalization: lowercase + remove all whitespace.
    /// Used solely for anchor containment; production rawText stays
    /// untouched.
    private static func compact(_ text: String) -> String {
        text.lowercased().filter { !$0.isWhitespace }
    }

    /// TEST-ONLY: decimal digits only (for phone anchors).
    private static func digits(_ text: String) -> String {
        text.filter(\.isNumber)
    }

    /// Runs the full in-place chain and returns the raw OCR result.
    private func recognizeCard(_ imageName: String) async throws -> CardOCRResult {
        let url = Self.repoRoot.appending(path: "dataset/cards/\(imageName)")
        let data = try Data(contentsOf: url)
        let photo = CapturedPhoto(data: data)

        let cropProcessor = CardCropProcessor()
        let preparation = try await cropProcessor.prepare(photo)

        #expect(
            preparation.wasDetected,
            "real still detection must find the card in \(imageName)"
        )
        #expect(CardRegionGeometry.isValid(preparation.draft.region))

        // The Increment 5 processed upright PNG is the mandatory input
        // to OCR — it must not be bypassed.
        let cropResult = try await cropProcessor.perspectiveCorrect(preparation.draft)
        #expect(cropResult.processedPixelWidth > 0)
        #expect(cropResult.processedPixelHeight > 0)

        return try await CardOCRProcessor().recognize(cropResult)
    }

    @Test("card-001 standard bilingual: full chain preserves raw anchors")
    func card001StandardBilingual() async throws {
        let result = try await recognizeCard("card-001-standard-bilingual.png")

        #expect(!result.rawText.isEmpty, "raw text must not be empty for card-001")
        #expect(result.rawText == result.lines.map(\.text).joined(separator: "\n"))

        let compact = Self.compact(result.rawText)
        #expect(compact.contains("张伟"), "Chinese name anchor (raw: \(result.rawText))")
        #expect(Self.digits(result.rawText).contains("13800138000"),
                "mobile anchor (raw: \(result.rawText))")
        #expect(compact.contains("zhiyuntech"),
                "domain anchor (raw: \(result.rawText))")
    }

    @Test("card-004 minimal name+mobile (photographed): raw anchors")
    func card004MinimalNameMobile() async throws {
        let result = try await recognizeCard("card-004-minimal-name-mobile.png")

        #expect(!result.rawText.isEmpty, "raw text must not be empty for card-004")

        let compact = Self.compact(result.rawText)
        #expect(compact.contains("张伟"), "Chinese name anchor (raw: \(result.rawText))")
        #expect(Self.digits(result.rawText).contains("13800138000"),
                "mobile anchor (raw: \(result.rawText))")
    }

    /// card-013's dataset PNG does not match its frozen ground truth
    /// (image shows Kevin Park / Morningside Secure Systems; frozen
    /// card-013 GT is Daniel Wu / Stonepine BioSystems, and card-014
    /// GT matches the card-013 image — a frozen dataset image/GT
    /// mismatch, not an OCR defect). This smoke is intentionally
    /// BLOCKED until the frozen dataset is resolved; the dataset is
    /// NOT modified here.
    @Test(
        "card-013 frozen dataset image/GT mismatch — blocked",
        .disabled("card-013 PNG shows Kevin Park but frozen GT is Daniel Wu; dataset integrity issue, dataset not modified")
    )
    func card013EnglishBioPhotographed() async throws {
        _ = try await recognizeCard("card-013-english-bio-photographed.png")
    }

    /// Third OCR functional smoke uses card-016: its PNG ↔ frozen GT
    /// are manually confirmed consistent (Michael Chen / CloudMatrix
    /// Inc., English, clean synthetic card with visible white boundary).
    /// Replaces the blocked card-013 entry.
    @Test("card-016 English software engineer (synthetic): raw anchors")
    func card016EnglishSoftwareEngineer() async throws {
        let result = try await recognizeCard("card-016-en-software-engineer.png")

        #expect(!result.rawText.isEmpty, "raw text must not be empty for card-016")

        let compact = Self.compact(result.rawText)
        #expect(compact.contains("michael"), "given-name anchor (raw: \(result.rawText))")
        #expect(compact.contains("chen"), "family-name anchor (raw: \(result.rawText))")
        #expect(compact.contains("cloudmatrix"),
                "domain anchor (raw: \(result.rawText))")
        #expect(Self.digits(result.rawText).contains("14155550199"),
                "mobile anchor (raw: \(result.rawText))")
    }
}
