//
//  CardOCRProcessorTests.swift
//  SimCamCardTests
//
//  Unit tests for T07 raw OCR (Week 3 Increment 6):
//
//    1. OCRConfiguration pure value — the exact request semantics of
//       the raw-text increment (accurate / zh-Hans+en-US / auto
//       language ON / language correction OFF).
//    2. CardOCRResult transport — lines preserved verbatim and joined
//       into rawText with "\n" (deterministic preservation contract).
//    3. The REAL CardOCRProcessor against real Vision: rendered text
//       yields preserved lines; a textless image yields a legitimate
//       EMPTY result (not an error); invalid bytes map to
//       OCRError.recognitionFailed.
//
//  Real photographed cards are covered end-to-end in
//  OCRPipelineDatasetSmokeTests. OCR output is probabilistic, so the
//  real-Vision assertions use stable anchors and never pin a full
//  transcript.
//

import Foundation
import CoreGraphics
import CoreText
import ImageIO
import Vision
import Testing
@testable import SimCamCard

@Suite("CardOCRProcessor")
struct CardOCRProcessorTests {

    private enum OCRTestError: Error {
        case contextFailed
        case imageFailed
        case encodeFailed
    }

    // MARK: - Configuration

    @Test("default OCR configuration encodes the T07 raw-text contract")
    func defaultConfigurationEncodesRawContract() {
        let config = OCRConfiguration()

        #expect(config.recognitionLevel == .accurate)
        #expect(config.automaticallyDetectsLanguage)
        // Language correction must stay OFF: raw preservation first.
        #expect(!config.usesLanguageCorrection)
        // Simplified Chinese first, then US English.
        #expect(config.recognitionLanguages.first == Locale.Language(identifier: "zh-Hans"))
        #expect(config.recognitionLanguages.contains(Locale.Language(identifier: "en-US")))
    }

    // MARK: - Raw preservation (deterministic transport contract)

    @Test("rawText preserves order and verbatim characters, newline-joined")
    func rawTextIsVerbatimNewlineJoin() {
        let crop = makeCrop(pngData: Self.blankPNGData)
        let lines = [
            OCRLine(text: "张伟", confidence: 0.91),
            OCRLine(text: "+86 138 0013 8000", confidence: 0.8),
            OCRLine(text: "wei.zhang@zhiyuntech.com", confidence: 0.99),
        ]
        let result = CardOCRResult(cropResult: crop, lines: lines)

        // Order, punctuation, digits, spaces, case and CJK are carried
        // through untouched.
        #expect(result.lines == lines)
        #expect(result.rawText == "张伟\n+86 138 0013 8000\nwei.zhang@zhiyuntech.com")

        // Zero lines is a legitimate empty raw result.
        let empty = CardOCRResult(cropResult: crop, lines: [])
        #expect(empty.lines.isEmpty)
        #expect(empty.rawText.isEmpty)
    }

    // MARK: - Real Vision (no fakes)

    @Test("real Vision recognizes text rendered into an image")
    func realVisionRecognizesRenderedText() async throws {
        let png = try makeTextPNG(
            lines: ["Wei Zhang", "+86 138 0013 8000", "wei.zhang@zhiyuntech.com"]
        )
        let result = try await CardOCRProcessor().recognize(makeCrop(pngData: png))

        #expect(!result.lines.isEmpty, "real Vision should return lines (raw: \(result.rawText))")
        #expect(!result.rawText.isEmpty)

        // Stable anchors with TEST-ONLY whitespace-insensitive
        // normalization — the raw value itself is never normalized.
        let compact = result.rawText.lowercased().filter { !$0.isWhitespace }
        #expect(
            compact.contains("13800138000"),
            "phone anchor must survive verbatim (raw: \(result.rawText))"
        )
        #expect(
            compact.contains("wei.zhang@zhiyuntech.com"),
            "email anchor must survive verbatim (raw: \(result.rawText))"
        )

        // rawText must be exactly the newline-join of the exposed lines.
        #expect(result.rawText == result.lines.map(\.text).joined(separator: "\n"))
        // Confidence is metadata in a valid range, never a filter.
        #expect(result.lines.allSatisfy { (0.0...1.0).contains($0.confidence) })
    }

    @Test("a textless image yields a legitimate empty result, not an error")
    func textlessImageYieldsEmptyResult() async throws {
        let result = try await CardOCRProcessor().recognize(
            makeCrop(pngData: Self.blankPNGData)
        )

        #expect(result.lines.isEmpty)
        #expect(result.rawText.isEmpty)
    }

    @Test("undecodable bytes map to OCRError.recognitionFailed")
    func invalidBytesMapToRecognitionFailed() async {
        do {
            _ = try await CardOCRProcessor().recognize(
                makeCrop(pngData: Data([0x01, 0x02, 0x03, 0x04]))
            )
            Issue.record("invalid bytes must throw OCRError.recognitionFailed")
        } catch let error as OCRError {
            #expect(error == .recognitionFailed)
        } catch {
            Issue.record("expected OCRError, got \(error)")
        }
    }

    // MARK: - Fixtures

    /// Wraps PNG bytes as a minimal crop result (fields beyond
    /// processedImageData are irrelevant to raw recognition).
    private func makeCrop(pngData: Data) -> CardCropResult {
        let photo = CapturedPhoto(data: pngData)
        let region = CardRegion(
            topLeft: NormalizedPoint(x: 0.1, y: 0.1),
            topRight: NormalizedPoint(x: 0.9, y: 0.1),
            bottomRight: NormalizedPoint(x: 0.9, y: 0.9),
            bottomLeft: NormalizedPoint(x: 0.1, y: 0.9),
            sourcePixelWidth: 100,
            sourcePixelHeight: 100
        )
        return CardCropResult(
            original: photo,
            confirmedRegion: region,
            processedImageData: pngData,
            processedPixelWidth: 100,
            processedPixelHeight: 100
        )
    }

    /// Blank opaque white 320×200 RGBA PNG (deterministic, no Vision
    /// text expected).
    private static let blankPNGData: Data = {
        let width = 320
        let height = 200
        let pixels = [UInt8](repeating: 255, count: width * height * 4)
        guard let data = encodePNG(
            pixels: pixels, width: width, height: height
        ) else {
            return Data()
        }
        return data
    }()

    /// Renders black left-aligned text lines on a white opaque RGBA
    /// bitmap and encodes PNG. Core Text only — no UIKit.
    private func makeTextPNG(lines: [String]) throws -> Data {
        let width = 760
        let height = 420
        var pixels = [UInt8](repeating: 255, count: width * height * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw OCRTestError.contextFailed
        }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 44, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String):
                CGColor(red: 0, green: 0, blue: 0, alpha: 1),
        ]

        // Native bottom-left bitmap coordinates: the first baseline
        // sits near the top and each following line descends.
        var y: CGFloat = CGFloat(height) - 74
        for line in lines {
            let ctLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: line, attributes: attributes)
            )
            context.textPosition = CGPoint(x: 48, y: y)
            CTLineDraw(ctLine, context)
            y -= 88
        }

        guard let cgImage = context.makeImage(),
              let data = Self.encodePNG(pixels: pixels, width: width, height: height)
        else {
            throw OCRTestError.imageFailed
        }
        return data
    }

    /// Encodes an RGBA premultiplied-last pixel buffer as PNG.
    private static func encodePNG(pixels: [UInt8], width: Int, height: Int) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            return nil
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, "public.png" as CFString, 1, nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination), output.length > 0 else {
            return nil
        }
        return output as Data
    }
}
