//
//  RecognitionView.swift
//  SimCamCard
//
//  P05 Recognition / Edit Card form (Week 4 Increment 2).
//
//  Replaces the Week 3 transitional raw-text surface. All settled
//  structured states (structuredResultAvailable / missingFields /
//  multiplePhoneFields / nonCardEmptyResult) render the SAME P05 form
//  layout; the difference is ONLY data + state marker.
//
//  Reference fidelity (REF-recognition-03/04 card-b): card-b has no
//  website and its 首页 row is OMITTED ENTIRELY. That omission evidence
//  is scoped to website only — no "N/A" / "未识别" / placeholder, no
//  fabricated value.
//
//  Row-existence policy is deliberately narrow:
//   - website: the row exists only when website != nil (card-b evidence).
//   - phones/emails: one row per actual array element (existing behavior).
//   - name/company/jobTitle/address: fixed structural rows always present;
//     a nil value renders an empty row. Their missing-row behavior is NOT
//     claimed until dedicated Reference evidence exists — the card-b
//     website omission must not be generalized to every scalar field.
//
//  Week 4 Increment 2 is READ-ONLY: fields are `Text`, not TextField/
//  TextEditor / Binding. T11 editable increment will replace them.
//
//  Recovery action: 重拍 returns to Scanner via the existing retake path.
//  NO Save button, NO BusinessCard creation, NO Repository write.
//
//  Raw OCR preservation: StructuredRecognitionResult.ocrResult is
//  carried in state; rawText is not displayed as the primary UI but
//  remains intact for later increments.
//

import SwiftUI

struct RecognitionView: View {

    let viewModel: ScanViewModel

    private static let recognitionBlue = Color(red: 0.0, green: 0.62, blue: 1.0)
    private static let formBackground = Color(white: 0.11)
    private static let separatorColor = Color(white: 0.18)
    private static let labelColor = Color(red: 0.0, green: 0.50, blue: 0.90)
    private static let imageFraction: CGFloat = 0.36

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .accessibilityElement()
                .accessibilityIdentifier("scan-recognition-form")

            switch viewModel.recognition {
            case .inactive:
                Color.clear
            case .processing(let crop):
                processingContent(crop)
            case .structuredResultAvailable(let result):
                formContent(result, stateMarker: "scan-recognition-structured")
            case .nonCardEmptyResult(let result):
                formContent(result, stateMarker: "scan-recognition-empty")
            case .missingFields(let result):
                formContent(result, stateMarker: "scan-recognition-missing")
            case .multiplePhoneFields(let result):
                formContent(result, stateMarker: "scan-recognition-multiple")
            case .failed(let error):
                failedContent(error)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Processing

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
        .accessibilityElement()
        .accessibilityIdentifier("scan-recognition-processing")
    }

    // MARK: - P05 Structured Form

    private func formContent(
        _ result: StructuredRecognitionResult,
        stateMarker: String
    ) -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topBar
                cropImage(result.ocrResult.cropResult.processedImageData)
                    .frame(height: proxy.size.height * Self.imageFraction)

                ScrollView {
                    VStack(spacing: 0) {
                        stateAccessibility(marker: stateMarker)
                        basicFieldRow(label: "姓名", value: result.fields.name, id: "scan-field-name")
                        phoneRows(result.fields.phones)
                        emailRows(result.fields.emails)
                        basicFieldRow(label: "公司", value: result.fields.company, id: "scan-field-company")
                        basicFieldRow(label: "职位", value: result.fields.jobTitle, id: "scan-field-job-title")
                        // Website is the ONLY scalar row whose existence is
                        // data-driven (Reference card-b: missing website →
                        // 首页 row entirely absent).
                        if let website = result.fields.website {
                            basicFieldRow(label: "首页", value: website, id: "scan-field-website")
                        }
                        basicFieldRow(label: "公司地址", value: result.fields.address, id: "scan-field-address")
                    }
                }
            }
        }
    }

    /// Hidden accessibility marker for the current structured state.
    private func stateAccessibility(marker: String) -> some View {
        Text("")
            .accessibilityElement()
            .accessibilityIdentifier(marker)
            .frame(height: 0)
    }

    // MARK: - Field rows

    /// Generic label + read-only value row. A nil value renders an
    /// empty-but-present row (name/company/jobTitle/address are fixed
    /// structural rows). Row EXISTENCE is decided by callers only for
    /// website (omitted per card-b) and for phone/email rows (one per
    /// actual element); no "N/A" / "未识别" placeholder is ever shown.
    private func basicFieldRow(
        label: String,
        value: String?,
        id: String
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(Self.labelColor)
                    .frame(width: 72, alignment: .leading)
                Text(value ?? "")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(height: 48)
            .padding(.horizontal, 16)

            Divider()
                .background(Self.separatorColor)
                .padding(.leading, 100)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(id)
    }

    /// Renders every PhoneNumber as a labeled row, preserving stored
    /// order and kind. Multiple numbers of the same kind each get their
    /// own row with indexed accessibility identifier (per-kind index).
    private func phoneRows(_ phones: [PhoneNumber]) -> some View {
        ForEach(Array(phones.enumerated()), id: \.element.id) { index, phone in
            let (label, baseID) = phoneKindLabel(phone.kind)
            let kindIndex = phones[0..<index].filter { $0.kind == phone.kind }.count
            basicFieldRow(
                label: label,
                value: phone.value,
                id: "\(baseID)-\(kindIndex)"
            )
        }
    }

    /// Email rows preserving stored order with indexed identifiers.
    private func emailRows(_ emails: [String]) -> some View {
        ForEach(Array(emails.enumerated()), id: \.offset) { index, email in
            basicFieldRow(
                label: "工作邮箱",
                value: email,
                id: "scan-field-email-\(index)"
            )
        }
    }

    /// Canonical kind → CN label + accessibility base id.
    private func phoneKindLabel(_ kind: PhoneNumber.Kind) -> (label: String, baseID: String) {
        switch kind {
        case .mobile:
            return ("手机", "scan-field-mobile")
        case .office:
            return ("工作电话", "scan-field-office")
        case .fax:
            return ("工作传真", "scan-field-fax")
        case .other:
            return ("其他电话", "scan-field-other-phone")
        }
    }

    // MARK: - Failure

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
        .accessibilityElement()
        .accessibilityIdentifier("scan-recognition-failed")
    }

    private func message(for error: OCRError) -> String {
        switch error {
        case .recognitionFailed:
            "文字识别未能完成，请重拍后重试。"
        }
    }

    // MARK: - Shared chrome

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
