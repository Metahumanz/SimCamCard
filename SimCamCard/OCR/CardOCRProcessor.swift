//
//  CardOCRProcessor.swift
//  SimCamCard
//
//  Raw text recognition service (Week 3 Increment 6 — T07).
//
//  Pipeline:
//    CardCropResult.processedImageData (physically upright PNG)
//    → Swift-native Vision RecognizeTextRequest
//    → [RecognizedTextObservation]
//    → OCRLine[] (top-1 candidate, verbatim) + preserved rawText
//
//  T07 is RAW ONLY:
//   - .accurate bilingual recognition (Simplified Chinese first, then
//     US English), automatic language detection ON
//   - language correction OFF and no customWords: nothing may rewrite
//     the raw text before Week 4 structured extraction
//   - no field parsing, no regex classifier, no reading-order rewrite,
//     no space/punctuation/case normalization, no confidence filtering
//
//  Concurrency: a plain `actor` isolates processor state and keeps
//  Vision types behind the processor boundary. Only Sendable project
//  values (CardCropResult / CardOCRResult) cross it;
//  RecognizedTextObservation never leaves this actor and never
//  reaches the ViewModel/View.
//
//  Because Swift actors are reentrant across await points, actor
//  isolation alone does NOT guarantee that two Vision perform calls
//  can never overlap.
//
//  ScanViewModel owns at most one current recognition Task. Starting
//  a new recognition cancels and supersedes the previously owned
//  Task. recognitionGeneration guarantees that stale completion from
//  an older recognition cannot mutate the current workflow state.
//  Task cancellation does not establish that an already-running
//  Vision request aborts immediately; underlying early-abort behavior
//  remains framework-dependent. This actor deliberately does NOT
//  promise non-reentrant execution.
//
//  NOT `@unchecked Sendable`, NOT `nonisolated(unsafe)`, NOT
//  `Task.detached`.
//

import Foundation
import Vision
import ImageIO

/// Abstract OCR-processing seam — lets deterministic unit/UI tests
/// inject a controllable recognition result while the MainActor
/// ViewModel stays decoupled from the concrete Vision service.
nonisolated protocol CardOCRProcessing: Sendable {
    /// Recognizes raw text in `crop.processedImageData` (already
    /// physically upright). A request that yields ZERO observations
    /// returns an EMPTY `CardOCRResult` — it never throws. Throws
    /// `OCRError` only when the recognition request itself fails.
    func recognize(_ crop: CardCropResult) async throws -> CardOCRResult
}

/// Pure, testable configuration for the raw recognition request.
/// Kept separate from the actor so tests can assert the exact T07
/// request semantics without running Vision.
nonisolated struct OCRConfiguration: Sendable, Equatable {

    var recognitionLevel: RecognizeTextRequest.RecognitionLevel
    var recognitionLanguages: [Locale.Language]
    var automaticallyDetectsLanguage: Bool
    var usesLanguageCorrection: Bool

    init(
        recognitionLevel: RecognizeTextRequest.RecognitionLevel = .accurate,
        recognitionLanguages: [Locale.Language] = [
            // Simplified Chinese first (bilingual cards), then US
            // English. Order is preference, not exclusion.
            Locale.Language(identifier: "zh-Hans"),
            Locale.Language(identifier: "en-US"),
        ],
        automaticallyDetectsLanguage: Bool = true,
        usesLanguageCorrection: Bool = false
    ) {
        self.recognitionLevel = recognitionLevel
        self.recognitionLanguages = recognitionLanguages
        self.automaticallyDetectsLanguage = automaticallyDetectsLanguage
        self.usesLanguageCorrection = usesLanguageCorrection
    }

    /// Builds the Swift-native Vision request. Revision is left at the
    /// system default. The request value never leaves the processor
    /// actor.
    func makeRequest() -> RecognizeTextRequest {
        var request = RecognizeTextRequest()
        request.recognitionLevel = recognitionLevel
        request.recognitionLanguages = recognitionLanguages
        request.automaticallyDetectsLanguage = automaticallyDetectsLanguage
        request.usesLanguageCorrection = usesLanguageCorrection
        // T07 deliberately sets no customWords: raw preservation first.
        return request
    }
}

actor CardOCRProcessor: CardOCRProcessing {

    private let configuration: OCRConfiguration

    init(configuration: OCRConfiguration = OCRConfiguration()) {
        self.configuration = configuration
    }

    func recognize(_ crop: CardCropResult) async throws -> CardOCRResult {
        let request = configuration.makeRequest()

        let observations: [RecognizedTextObservation]
        do {
            // The processed PNG is physically upright with no EXIF
            // orientation; pass .up explicitly so orientation is never
            // re-interpreted.
            observations = try await request.perform(
                on: crop.processedImageData,
                orientation: .up
            )
        } catch {
            // Invalid image data / Vision failure: stable error, never
            // a crash, never disguised as an empty result.
            throw OCRError.recognitionFailed
        }

        // Preserve Vision's observation order. Per observation keep
        // ONLY the top-1 candidate; strip solely surrounding
        // whitespace/newlines (drop empty lines). Confidence is stored
        // as metadata, never used to filter or reorder.
        var lines: [OCRLine] = []
        lines.reserveCapacity(observations.count)
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else {
                continue
            }
            let trimmed = candidate.string.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !trimmed.isEmpty else { continue }
            lines.append(OCRLine(text: trimmed, confidence: candidate.confidence))
        }

        return CardOCRResult(cropResult: crop, lines: lines)
    }
}
