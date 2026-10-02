//
//  CropPipelineDatasetSmokeTests.swift
//  SimCamCardTests
//
//  End-to-end dataset smoke for the shared still pipeline
//  (Week 3 Increment 5):
//
//    dataset PNG → CardCropProcessor.prepare (real decode + real
//    Vision rectangle detection) → CardCropProcessor.perspectiveCorrect
//    → valid physically-upright PNG
//
//  These are SMOKE tests, not pixel-diff assertions: they prove the
//  real Increment 4 detector and the new Increment 5 processing chain
//  compose on actual photographed/dataset cards without fixtures, and
//  that the output is a decodable upright image.
//
//  Dataset files are read in place and never modified.
//

import Foundation
import ImageIO
import Testing
@testable import SimCamCard

@Suite("Crop pipeline dataset smoke")
struct CropPipelineDatasetSmokeTests {

    /// Repository root derived from this file's path:
    /// <root>/SimCamCardTests/Crop/CropPipelineDatasetSmokeTests.swift
    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Crop/
        .deletingLastPathComponent()  // SimCamCardTests/
        .deletingLastPathComponent()  // <root>

    @Test("dataset card: decode → detect → correct → upright PNG", arguments: [
        "card-001-standard-bilingual.png",
        "card-007-vertical-medical-bilingual.png",
        "card-013-english-bio-photographed.png",
    ])
    func fullPipelineOnDatasetCard(imageName: String) async throws {
        let url = Self.repoRoot.appending(path: "dataset/cards/\(imageName)")
        let data = try Data(contentsOf: url)
        let photo = CapturedPhoto(data: data)

        let processor = CardCropProcessor()
        let preparation = try await processor.prepare(photo)

        #expect(
            preparation.wasDetected,
            "real still-image detection must find the card in \(imageName)"
        )
        #expect(preparation.draft.sourcePixelWidth > 0)
        #expect(preparation.draft.sourcePixelHeight > 0)
        #expect(CardRegionGeometry.isValid(preparation.draft.region))

        let result = try await processor.perspectiveCorrect(preparation.draft)

        #expect(result.processedPixelWidth > 0, "positive output width for \(imageName)")
        #expect(result.processedPixelHeight > 0, "positive output height for \(imageName)")
        #expect(result.original == photo, "original bytes must be retained for \(imageName)")

        // Output contract: decodable, no residual orientation metadata.
        let decoded = try CardImageDecoder.decode(result.processedImageData)
        #expect(decoded.orientation == .up)
        #expect(decoded.orientedPixelWidth == result.processedPixelWidth)
        #expect(decoded.orientedPixelHeight == result.processedPixelHeight)
    }
}
