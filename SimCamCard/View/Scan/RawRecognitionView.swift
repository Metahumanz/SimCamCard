//
//  RawRecognitionView.swift
//  SimCamCard
//
//  T07 raw OCR result screen (Week 3 Increment 6).
//
//  Spec source: spec/state-inventory.md S05 — this increment
//  implements ONLY the raw transport surface (`processing` and the
//  raw/empty/failure outcomes). The frozen S05 structured states
//  (structuredResultAvailable / missingFields / multiplePhoneFields /
//  manualEditing) and the P05 structured Recognition/Edit page are
//  Week 4 work and are deliberately absent.
//
//  IMPORTANT — Reference fidelity NOT established: the CamCard
//  raw-text screen was not externally exposed/observed during
//  evidence gathering (spec/reference-tests.md T07: "CamCard raw-text
//  screen was not externally exposed in current observation"). This
//  is therefore a minimal TRANSITIONAL IMPLEMENTATION surface that
//  displays the preserved raw text (selectable, NOT editable), never
//  a CamCard Reference page.
//
//  Deliberately absent in T07:
//   - structured fields (name / company / title / phone / email /
//     address) and any parser-driven UI
//   - text editing (no TextField; system text selection only)
//   - Save and any Repository/BusinessCard write
//   - navigation into P06/P07
//  The only recovery action is 重拍, which returns to the Scanner via
//  the existing retake path and invalidates the crop + recognition.
//
//  Presentation only: no Vision types, no processing — UIImage(data:)
//  is solely the display adapter for the processed upright PNG.
//

import SwiftUI

struct RawRecognitionView: View {

    /// MainActor @Observable owner, shared with ScanEntryView.
    let viewModel: ScanViewModel

    /// T07 accent matching the P04 boundary blue.
    private static let recognitionBlue = Color(red: 0.0, green: 0.62, blue: 1.0)
    private static let imageFraction: CGFloat = 0.36

    var body: some View {
        ZStack {
            // Root marker on a childless layer (a container-level
            // identifier would propagate onto child buttons).
            Color.black
                .ignoresSafeArea()
                .accessibilityElement()
                .accessibilityIdentifier(rootIdentifier)

            switch viewModel.recognition {
            case .inactive:
                // Scanner/Crop owns the screen while recognition is off.
                Color.clear
            case .processing(let crop):
                processingContent(crop)
            case .rawTextAvailable(let result):
                rawTextContent(result)
            case .emptyRawResult(let result):
                emptyContent(result)
            case .failed(let error):
                failedContent(error)
            }
        }
        .preferredColorScheme(.dark)
    }

    /// State-specific root identifier. The raw-text screen uses
    /// `scan-recognition-view`; transient/failure states get their own.
    private var rootIdentifier: String {
        switch viewModel.recognition {
        case .inactive, .rawTextAvailable:
            return "scan-recognition-view"
        case .processing:
            return "scan-recognition-processing"
        case .emptyRawResult:
            return "scan-recognition-empty"
        case .failed:
            return "scan-recognition-failed"
        }
    }

    // MARK: - Processing

    /// Implementation transient: processed image with a spinner. The
    /// Reference shows no raw processing page; fidelity not
    /// established and no animation is faked.
    private func processingContent(_ crop: CardCropResult) -> some View {
        VStack(spacing: 0) {
            topBar
            ZStack {
                cropImage(crop.processedImageData)
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("正在识别…")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Raw text

    /// Transitional raw-result surface: the processed upright image
    /// plus the preserved raw text. Selection is enabled (copy),
    /// editing is not.
    private func rawTextContent(_ result: CardOCRResult) -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topBar
                cropImage(result.cropResult.processedImageData)
                    .frame(height: proxy.size.height * Self.imageFraction)

                HStack {
                    Text("原始识别文本")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)

                ScrollView {
                    // Identifier on the Text itself: its accessibility
                    // label is then the full preserved raw string.
                    Text(result.rawText)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .accessibilityIdentifier("scan-recognition-raw-text")
                }
            }
        }
    }

    // MARK: - Empty

    /// Legitimate zero-text outcome. NOT a failure, no fabricated
    /// fields, and no automatic return to the Scanner — the user
    /// chooses 重拍. Foundation for Week 4 nonCardEmptyResult.
    private func emptyContent(_ result: CardOCRResult) -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topBar
                cropImage(result.cropResult.processedImageData)
                    .frame(height: proxy.size.height * Self.imageFraction)
                Spacer(minLength: 0)
                VStack(spacing: 14) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("未识别到文字")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("名片区域未识别出文字，请重拍或调整名片位置后再试。")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Failure

    /// Stable recovery for a failed recognition request. Never
    /// disguised as an empty result; 重拍 returns to the Scanner.
    private func failedContent(_ error: OCRError) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
            Text("识别失败")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            Text(message(for: error))
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.retake() }
            } label: {
                Text("重拍")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Self.recognitionBlue)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
            }
            .accessibilityIdentifier("scan-recognition-retake")
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func message(for error: OCRError) -> String {
        switch error {
        case .recognitionFailed:
            "文字识别未能完成，请重拍后重试。"
        }
    }

    // MARK: - Shared chrome

    /// Minimal top bar: the single recovery action 重拍 (returns to the
    /// Scanner via the existing P04 retake path, discarding crop and
    /// recognition). No Save, no Cancel-to-edit in T07.
    private var topBar: some View {
        HStack {
            Button {
                Task { await viewModel.retake() }
            } label: {
                Text("重拍")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .frame(minWidth: 56, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("scan-recognition-retake")
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    /// Aspect-fit display of the processed PNG. UIImage exists only as
    /// this View-layer adapter; the Data remains the source of truth.
    private func cropImage(_ data: Data) -> some View {
        Group {
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}
