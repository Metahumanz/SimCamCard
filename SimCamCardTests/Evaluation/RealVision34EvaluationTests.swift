//
//  RealVision34EvaluationTests.swift
//  SimCamCardTests
//
//  Final Delivery Phase 1 — REAL Vision 34-card OCR evaluation harness.
//
//  This is NOT a deterministic unit test. It runs the 34 frozen dataset
//  PNGs through the REAL production pipeline (Vision rectangle detection
//  + Core Image perspective correction + Swift-native Vision OCR +
//  deterministic CardFieldExtractor), compares every field against the
//  frozen Ground Truth, and emits evaluation artifacts.
//
//  Pipeline per card:
//    Image Data → CapturedPhoto
//    → CardCropProcessor.prepare      (real Vision rectangle detection;
//                                       no-detection → inset fallback)
//    → CardCropProcessor.perspectiveCorrect (Core Image upright PNG)
//    → CardOCRProcessor.recognize     (real Swift-native Vision OCR)
//    → CardFieldExtractor.extract     (deterministic parsing)
//
//  Gating: the suite is `.disabled` unless REAL_VISION_EVAL=1 is set in
//  the test-runner environment (xcodebuild: prefix with TEST_RUNNER_),
//  so the deterministic 431-test baseline NEVER includes it. No GT
//  values are synthesized into OCR lines — every byte comes from the
//  real PNG. The GT JSON is used ONLY as expected values for scoring.
//
//  Artifacts are written to EVAL_OUTPUT_DIR (host path; falls back to
//  <repo>/ai/evaluation/real-vision-34). The full payload is ALSO
//  printed between markers so a host-side script can reconstruct the
//  artifacts even if the simulator sandbox denies host-path writes.
//
//  Repeat:
//    TEST_RUNNER_REAL_VISION_EVAL=1 xcodebuild test \
//      -scheme SimCamCard \
//      -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
//      -only-testing:SimCamCardTests/RealVision34EvaluationTests \
//      -parallel-testing-enabled NO
//

import Foundation
import ImageIO
import Testing
@testable import SimCamCard

@Suite("Real Vision 34-card evaluation (non-deterministic, env-gated)")
struct RealVision34EvaluationTests {

    private static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["REAL_VISION_EVAL"] == "1"
    }

    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Evaluation/
        .deletingLastPathComponent()  // SimCamCardTests/
        .deletingLastPathComponent()  // <root>

    private static var outputDir: URL {
        if let custom = ProcessInfo.processInfo.environment["EVAL_OUTPUT_DIR"],
           !custom.isEmpty {
            return URL(fileURLWithPath: custom, isDirectory: true)
        }
        return repoRoot
            .appending(path: "ai/evaluation/real-vision-34", directoryHint: .isDirectory)
    }

    // MARK: - Codable payloads

    private struct RawRecord: Codable {
        let id: String
        let file: String
        let pipelineError: String?
        let wasDetected: Bool
        let detectedRegionNormalizedArea: Double
        let regionTopLeft: [Double]
        let regionTopRight: [Double]
        let regionBottomRight: [Double]
        let regionBottomLeft: [Double]
        let sourcePixelWidth: Int
        let sourcePixelHeight: Int
        let processedPixelWidth: Int
        let processedPixelHeight: Int
        let lineCount: Int
        let lines: [LineRecord]
        let rawText: String
        // Diagnostic only: OCR over the FULL upright image (identity
        // region, no detector quad). Separates detector false-positive
        // root causes from Vision OCR recognition limits. NOT part of
        // the primary scored pipeline.
        let diagError: String?
        let diagProcessedPixelWidth: Int
        let diagProcessedPixelHeight: Int
        let diagLineCount: Int
        let diagRawText: String
    }

    private struct LineRecord: Codable {
        let text: String
        let confidence: Double
    }

    private struct StructuredRecord: Codable {
        let id: String
        let name: String?
        let company: String?
        let jobTitle: String?
        let phones: [PhoneRecord]
        let emails: [String]
        let website: String?
        let address: String?
        let unclassifiedText: [String]
    }

    private struct PhoneRecord: Codable {
        let kind: String
        let value: String
    }

    private struct ComparisonRow: Codable {
        let id: String
        let field: String
        let gtPresent: Bool
        let gtValue: String
        let observedValue: String
        let rawContainsAnchor: Bool
        var fullImageContainsAnchor: Bool
        let match: Bool
        let errorType: String
        let note: String
    }

    private struct Payload: Codable {
        let environment: [String: String]
        let raw: [RawRecord]
        let structured: [StructuredRecord]
        let comparison: [ComparisonRow]
    }

    // MARK: - Normalization

    private static func compact(_ s: String?) -> String {
        (s ?? "").lowercased().filter { !$0.isWhitespace }
    }

    private static func digits(_ s: String?) -> String {
        (s ?? "").filter(\.isNumber)
    }

    /// For bilingual GT lines like "产品总监 | Product Director",
    /// return the native (pre-separator) side; falls back to whole.
    private static func nativeSide(_ s: String) -> String {
        let separators = [" | ", " |", "| ", "|", " ｜ "]
        for sep in separators {
            if let r = s.range(of: sep) {
                return String(s[..<r.lowerBound])
            }
        }
        return s
    }

    /// Website core: lowercase, strip scheme, leading www., trailing /.
    private static func websiteCore(_ s: String?) -> String {
        var c = compact(s)
        if c.hasPrefix("https://") { c.removeFirst(8) }
        if c.hasPrefix("http://") { c.removeFirst(7) }
        if c.hasPrefix("www.") { c.removeFirst(4) }
        while c.hasSuffix("/") { c.removeLast() }
        return c
    }

    /// Strict text match: full compact GT contained in compact observed.
    private static func textStrictMatch(gt: String, observed: String?) -> Bool {
        let g = compact(gt)
        guard !g.isEmpty else { return false }
        return compact(observed).contains(g)
    }

    /// Lenient bilingual match: native side compact contained.
    private static func textNativeMatch(gt: String, observed: String?) -> Bool {
        let g = compact(nativeSide(gt))
        guard !g.isEmpty else { return false }
        return compact(observed).contains(g)
    }

    private static func rawHasTextAnchor(gt: String, raw: String) -> Bool {
        compact(raw).contains(compact(nativeSide(gt)))
    }

    /// Whether the GT anchor for a field appears in the diagnostic
    /// full-image OCR text (root-cause separation only).
    private static func diagHasAnchor(
        field: String, gt: String, diagRaw: String
    ) -> Bool {
        guard !gt.isEmpty else { return false }
        switch field {
        case "mobile", "office", "fax":
            return diagRaw.filter(\.isNumber).contains(digits(gt))
        case "email":
            return compact(diagRaw).contains(compact(gt))
        case "website":
            let core = websiteCore(gt)
            return !core.isEmpty
                && (diagRaw.lowercased().contains(core)
                    || compact(diagRaw).contains(core))
        default:
            return rawHasTextAnchor(gt: gt, raw: diagRaw)
        }
    }

    // MARK: - Test

    @Test(
        "Real Vision 34-card evaluation (env REAL_VISION_EVAL=1)",
        .disabled(if: !isEnabled)
    )
    func evaluateAll34CardsWithRealVision() async throws {
        let cardsDir = Self.repoRoot.appending(path: "dataset/cards")
        let gtDir = Self.repoRoot.appending(path: "dataset/ground-truth")

        let files = try FileManager.default
            .contentsOfDirectory(atPath: cardsDir.path)
            .filter { $0.hasPrefix("card-") && $0.hasSuffix(".png") }
            .sorted()
        #expect(files.count == 34, "must evaluate exactly 34 frozen cards, got \(files.count)")

        var rawRecords: [RawRecord] = []
        var structuredRecords: [StructuredRecord] = []
        var comparisonRows: [ComparisonRow] = []

        for file in files {
            let cardID = String(file.split(separator: "-").prefix(2).joined(separator: "-"))
            let result = try await runOneCard(
                id: cardID,
                file: file,
                cardsDir: cardsDir
            )
            rawRecords.append(result.raw)
            structuredRecords.append(result.structured)

            let gtURL = gtDir.appending(path: "\(cardID).json")
            let gtData = try Data(contentsOf: gtURL)
            let gt = try JSONSerialization.jsonObject(with: gtData) as? [String: Any] ?? [:]

            func gtString(_ key: String) -> String? {
                guard let v = gt[key] as? String else { return nil }
                let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
                return t.isEmpty ? nil : t
            }

            let rawText = result.raw.rawText
            let s = result.structured

            // MARK: Text fields (name / company / jobTitle / address)

            func textRow(_ field: String, _ gtValue: String?, _ observed: String?, gtAlternate: String? = nil) {
                guard let g = gtValue else {
                    // GT absent. Before classifying as fabrication,
                    // check if the observed value matches an alternate-
                    // language GT variant (e.g. companyLatin when the
                    // canonical GT company is null). The frozen Domain
                    // deliberately keeps Latin counterparts in
                    // unclassifiedText, so a parser that promotes a
                    // Latin company line is not "fabricating" — it is
                    // recognizing a real GT field under a different
                    // language key. Bidirectional substring match handles
                    // both exact and partial overlaps.
                    let observedValue = observed ?? ""
                    let fabricated = !observedValue.isEmpty
                    if fabricated, let alt = gtAlternate, !alt.isEmpty {
                        let altStrict = Self.textStrictMatch(gt: alt, observed: observed)
                        let altReverse = Self.textStrictMatch(gt: observedValue, observed: alt)
                        if altStrict || altReverse {
                            comparisonRows.append(ComparisonRow(
                                id: cardID, field: field, gtPresent: false,
                                gtValue: "", observedValue: observedValue,
                                rawContainsAnchor: false,
                                fullImageContainsAnchor: false,
                                match: true,
                                errorType: "accepted_alternate_language",
                                note: "GT canonical field absent; observed value matches GT alternate-language variant (\(alt))"
                            ))
                            return
                        }
                    }
                    comparisonRows.append(ComparisonRow(
                        id: cardID, field: field, gtPresent: false,
                        gtValue: "", observedValue: observedValue,
                        rawContainsAnchor: false,
                        fullImageContainsAnchor: false,
                        match: !fabricated,
                        errorType: fabricated ? "fabrication" : "correct_absent",
                        note: ""
                    ))
                    return
                }
                let strict = Self.textStrictMatch(gt: g, observed: observed)
                let native = Self.textNativeMatch(gt: g, observed: observed)
                let rawHas = Self.rawHasTextAnchor(gt: g, raw: rawText)
                let errorType: String
                let note: String
                if strict {
                    errorType = "match"; note = ""
                } else if native {
                    errorType = "match_native_partial"
                    note = "native side matched; full bilingual GT string not contained"
                } else if observed == nil {
                    errorType = rawHas ? "extraction_miss" : "ocr_miss"
                    note = rawHas
                        ? "raw OCR contains anchor but extractor did not classify"
                        : "raw OCR does not contain the GT anchor"
                } else {
                    errorType = rawHas ? "wrong_value" : "ocr_miss"
                    note = rawHas
                        ? "raw OCR contains anchor but observed field value differs"
                        : "raw OCR lacks GT anchor; observed value may be OCR error"
                }
                comparisonRows.append(ComparisonRow(
                    id: cardID, field: field, gtPresent: true,
                    gtValue: g, observedValue: observed ?? "",
                    rawContainsAnchor: rawHas, fullImageContainsAnchor: false,
                    match: strict || native,
                    errorType: errorType, note: note
                ))
            }

            textRow("name", gtString("name"), s.name)
            textRow("company", gtString("company"), s.company,
                    gtAlternate: gtString("companyLatin"))
            textRow("jobTitle", gtString("jobTitle"), s.jobTitle)
            textRow("address", gtString("address"), s.address)

            // MARK: Phones (mobile / office / fax)

            func phoneRow(_ field: String, kind: PhoneNumber.Kind, _ gtValue: String?) {
                let matches = s.phones.filter { $0.kind == kind.rawValue }
                let gtDigits = Self.digits(gtValue)
                guard let g = gtValue, !gtDigits.isEmpty else {
                    let fabricated = !matches.isEmpty
                    comparisonRows.append(ComparisonRow(
                        id: cardID, field: field, gtPresent: false,
                        gtValue: "",
                        observedValue: matches.map(\.value).joined(separator: " | "),
                        rawContainsAnchor: false,
                        fullImageContainsAnchor: false,
                        match: !fabricated,
                        errorType: fabricated ? "fabrication" : "correct_absent",
                        note: ""
                    ))
                    return
                }
                let exactKind = matches.first { Self.digits($0.value) == gtDigits }
                let anyKind = s.phones.first { Self.digits($0.value) == gtDigits }
                let rawHas = rawText.filter(\.isNumber).contains(gtDigits)
                let observedText = matches.map(\.value).joined(separator: " | ")
                if exactKind != nil {
                    comparisonRows.append(ComparisonRow(
                        id: cardID, field: field, gtPresent: true, gtValue: g,
                        observedValue: observedText, rawContainsAnchor: rawHas, fullImageContainsAnchor: false,
                        match: true, errorType: "match", note: ""
                    ))
                } else if let wrong = anyKind {
                    comparisonRows.append(ComparisonRow(
                        id: cardID, field: field, gtPresent: true, gtValue: g,
                        observedValue: observedText, rawContainsAnchor: rawHas, fullImageContainsAnchor: false,
                        match: false, errorType: "kind_misclassification",
                        note: "digits found but classified as \(wrong.kind) instead of \(kind.rawValue)"
                    ))
                } else {
                    let errorType = rawHas ? "extraction_miss" : "ocr_miss"
                    comparisonRows.append(ComparisonRow(
                        id: cardID, field: field, gtPresent: true, gtValue: g,
                        observedValue: observedText, rawContainsAnchor: rawHas, fullImageContainsAnchor: false,
                        match: false, errorType: errorType,
                        note: rawHas
                            ? "raw OCR contains digits but not classified as \(kind.rawValue)"
                            : "raw OCR lacks the GT digits"
                    ))
                }
            }

            phoneRow("mobile", kind: .mobile, gtString("mobile"))
            phoneRow("office", kind: .office, gtString("phone"))
            phoneRow("fax", kind: .fax, gtString("fax"))

            // MARK: Email

            do {
                let gtEmail = gtString("email")?.lowercased()
                let obsEmails = s.emails.map { $0.lowercased() }
                if let g = gtEmail {
                    let matched = obsEmails.contains(g)
                    let rawHas = Self.compact(rawText).contains(Self.compact(g))
                    if matched {
                        comparisonRows.append(ComparisonRow(
                            id: cardID, field: "email", gtPresent: true, gtValue: g,
                            observedValue: obsEmails.joined(separator: " | "),
                            rawContainsAnchor: rawHas, fullImageContainsAnchor: false, match: true,
                            errorType: "match",
                            note: obsEmails.count > 1 ? "\(obsEmails.count - 1) extra email(s)" : ""
                        ))
                    } else {
                        let errorType = rawHas ? "extraction_miss" : "ocr_miss"
                        comparisonRows.append(ComparisonRow(
                            id: cardID, field: "email", gtPresent: true, gtValue: g,
                            observedValue: obsEmails.joined(separator: " | "),
                            rawContainsAnchor: rawHas, fullImageContainsAnchor: false, match: false,
                            errorType: errorType,
                            note: rawHas
                                ? "raw OCR contains email but extractor missed it"
                                : "raw OCR lacks the GT email"
                        ))
                    }
                } else {
                    // GT email absent: fabrication if extractor produced any.
                    let fabricated = !obsEmails.isEmpty
                    comparisonRows.append(ComparisonRow(
                        id: cardID, field: "email", gtPresent: false, gtValue: "",
                        observedValue: obsEmails.joined(separator: " | "),
                        rawContainsAnchor: false,
                        fullImageContainsAnchor: false, match: !fabricated,
                        errorType: fabricated ? "fabrication" : "correct_absent",
                        note: ""
                    ))
                }
            }

            // MARK: Website

            do {
                let gtSite = gtString("website")
                let gtCore = Self.websiteCore(gtSite)
                let obsCore = Self.websiteCore(s.website)
                if let g = gtSite, !gtCore.isEmpty {
                    let matched = !obsCore.isEmpty && obsCore == gtCore
                    let rawHas = rawText.lowercased().contains(gtCore)
                        || Self.compact(rawText).contains(gtCore)
                    if matched {
                        comparisonRows.append(ComparisonRow(
                            id: cardID, field: "website", gtPresent: true, gtValue: g,
                            observedValue: s.website ?? "", rawContainsAnchor: rawHas, fullImageContainsAnchor: false,
                            match: true, errorType: "match", note: ""
                        ))
                    } else if s.website != nil {
                        comparisonRows.append(ComparisonRow(
                            id: cardID, field: "website", gtPresent: true, gtValue: g,
                            observedValue: s.website ?? "", rawContainsAnchor: rawHas, fullImageContainsAnchor: false,
                            match: false,
                            errorType: rawHas ? "wrong_value" : "ocr_miss",
                            note: rawHas ? "anchor in raw OCR, observed value differs"
                                         : "raw OCR lacks website core token"
                        ))
                    } else {
                        comparisonRows.append(ComparisonRow(
                            id: cardID, field: "website", gtPresent: true, gtValue: g,
                            observedValue: "", rawContainsAnchor: rawHas, fullImageContainsAnchor: false,
                            match: false,
                            errorType: rawHas ? "extraction_miss" : "ocr_miss",
                            note: rawHas ? "raw OCR contains site but not classified"
                                         : "raw OCR lacks the website token"
                        ))
                    }
                } else {
                    let fabricated = !obsCore.isEmpty
                    comparisonRows.append(ComparisonRow(
                        id: cardID, field: "website", gtPresent: false, gtValue: "",
                        observedValue: s.website ?? "", rawContainsAnchor: false,
                        fullImageContainsAnchor: false,
                        match: !fabricated,
                        errorType: fabricated ? "fabrication" : "correct_absent",
                        note: ""
                    ))
                }
            }

            // Backfill diagnostic (full-image OCR) anchor presence for
            // the exactly 9 comparison rows produced by this card.
            let diagRaw = result.raw.diagRawText
            let cardRowsStart = comparisonRows.count - 9
            for index in cardRowsStart..<comparisonRows.count
            where comparisonRows[index].gtPresent {
                comparisonRows[index].fullImageContainsAnchor =
                    Self.diagHasAnchor(field: comparisonRows[index].field,
                                       gt: comparisonRows[index].gtValue,
                                       diagRaw: diagRaw)
            }
        }

        // MARK: Emit payload

        let env: [String: String] = [
            "runDate": ISO8601DateFormatter().string(from: Date()),
            "xcode": "27.0",
            "ios": "27.0",
            "simulator": "iPhone 18 Pro",
            "ocrEngine": "Vision RecognizeTextRequest (.accurate, zh-Hans+en-US, auto-detect ON, correction OFF)",
            "detector": "Vision VNDetectRectanglesRequest via CardRegionDetector",
            "crop": "CardCropProcessor actor + CIPerspectiveCorrection",
            "cards": "34 frozen dataset PNGs, unmodified",
            "gt": "dataset/ground-truth/card-001..034.json",
        ]
        let payload = Payload(
            environment: env, raw: rawRecords,
            structured: structuredRecords, comparison: comparisonRows
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = try encoder.encode(payload)

        try? FileManager.default.createDirectory(
            at: Self.outputDir,
            withIntermediateDirectories: true
        )
        let payloadURL = Self.outputDir.appending(path: "_eval-payload.json")
        var writeOK = false
        do {
            try json.write(to: payloadURL, options: .atomic)
            writeOK = FileManager.default.fileExists(atPath: payloadURL.path)
        } catch {
            writeOK = false
        }
        print("[real-vision-34] directWrite=\(writeOK) path=\(payloadURL.path)")
        print("[real-vision-34] cards=\(rawRecords.count) comparisonRows=\(comparisonRows.count)")
        let text = String(data: json, encoding: .utf8) ?? ""
        print("===EVAL-JSON-BEGIN===")
        print(text)
        print("===EVAL-JSON-END===")
    }

    // MARK: - Per-card pipeline

    private func runOneCard(
        id: String,
        file: String,
        cardsDir: URL
    ) async throws -> (raw: RawRecord, structured: StructuredRecord) {
        let url = cardsDir.appending(path: file)
        let data = try Data(contentsOf: url)
        let photo = CapturedPhoto(data: data, source: .photoLibrary)

        let cropProcessor = CardCropProcessor()
        var pipelineError: String?
        var wasDetected = false
        var region = CardRegion(
            topLeft: NormalizedPoint(x: 0, y: 0),
            topRight: NormalizedPoint(x: 1, y: 0),
            bottomRight: NormalizedPoint(x: 1, y: 1),
            bottomLeft: NormalizedPoint(x: 0, y: 1),
            sourcePixelWidth: 0, sourcePixelHeight: 0
        )
        var srcW = 0, srcH = 0, procW = 0, procH = 0
        var lines: [OCRLine] = []
        var rawText = ""
        var detectedArea = 0.0
        var sourceOrientation: CGImagePropertyOrientation = .up
        var diagError: String?
        var diagW = 0, diagH = 0
        var diagLines: [OCRLine] = []
        var diagRawText = ""

        do {
            let preparation = try await cropProcessor.prepare(photo)
            wasDetected = preparation.wasDetected
            region = preparation.draft.region
            srcW = preparation.draft.sourcePixelWidth
            srcH = preparation.draft.sourcePixelHeight
            sourceOrientation = preparation.draft.sourceOrientation
            detectedArea = CardRegionGeometry.normalizedArea(region)

            let cropResult = try await cropProcessor
                .perspectiveCorrect(preparation.draft)
            procW = cropResult.processedPixelWidth
            procH = cropResult.processedPixelHeight

            let ocr = try await CardOCRProcessor().recognize(cropResult)
            lines = ocr.lines
            rawText = ocr.rawText
        } catch {
            pipelineError = "\(error)"
        }

        // Diagnostic pass: FULL upright image through an identity region
        // (same orientation/dimensions metadata as the detected draft
        // when prepare succeeded; otherwise a zero-dim identity draft
        // is skipped). Root-cause separation only, never scored.
        do {
            let identityRegion = CardRegion(
                topLeft: NormalizedPoint(x: 0, y: 0),
                topRight: NormalizedPoint(x: 1, y: 0),
                bottomRight: NormalizedPoint(x: 1, y: 1),
                bottomLeft: NormalizedPoint(x: 0, y: 1),
                sourcePixelWidth: max(srcW, 1), sourcePixelHeight: max(srcH, 1)
            )
            let diagDraft = CropDraft(
                source: photo,
                sourceOrientation: sourceOrientation,
                sourcePixelWidth: max(srcW, 1),
                sourcePixelHeight: max(srcH, 1),
                region: identityRegion
            )
            let diagCrop = try await cropProcessor.perspectiveCorrect(diagDraft)
            diagW = diagCrop.processedPixelWidth
            diagH = diagCrop.processedPixelHeight
            let diagOCR = try await CardOCRProcessor().recognize(diagCrop)
            diagLines = diagOCR.lines
            diagRawText = diagOCR.rawText
        } catch {
            diagError = "\(error)"
        }

        // Build a minimal OCR result for the extractor even if the crop
        // failed (empty lines → empty structured fields).
        let emptyCrop = CardCropResult(
            original: photo, confirmedRegion: region,
            processedImageData: data,
            processedPixelWidth: procW, processedPixelHeight: procH
        )
        let ocrResult = CardOCRResult(cropResult: emptyCrop, lines: lines)
        let fields = CardFieldExtractor().extract(from: ocrResult).fields

        let raw = RawRecord(
            id: id, file: file, pipelineError: pipelineError,
            wasDetected: wasDetected,
            detectedRegionNormalizedArea: detectedArea,
            regionTopLeft: [region.topLeft.x, region.topLeft.y],
            regionTopRight: [region.topRight.x, region.topRight.y],
            regionBottomRight: [region.bottomRight.x, region.bottomRight.y],
            regionBottomLeft: [region.bottomLeft.x, region.bottomLeft.y],
            sourcePixelWidth: srcW, sourcePixelHeight: srcH,
            processedPixelWidth: procW, processedPixelHeight: procH,
            lineCount: lines.count,
            lines: lines.map { LineRecord(text: $0.text, confidence: Double($0.confidence)) },
            rawText: rawText,
            diagError: diagError,
            diagProcessedPixelWidth: diagW, diagProcessedPixelHeight: diagH,
            diagLineCount: diagLines.count,
            diagRawText: diagRawText
        )
        let structured = StructuredRecord(
            id: id,
            name: fields.name, company: fields.company, jobTitle: fields.jobTitle,
            phones: fields.phones.map { PhoneRecord(kind: $0.kind.rawValue, value: $0.value) },
            emails: fields.emails, website: fields.website, address: fields.address,
            unclassifiedText: fields.unclassifiedText
        )
        return (raw, structured)
    }
}
