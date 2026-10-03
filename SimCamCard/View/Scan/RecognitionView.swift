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
//  Week 4 Increment 2 shipped the READ-ONLY form. Week 4 Increment 3
//  (T11) adds S05 manualEditing: an explicit 编辑 entry transitions
//  the settled form into an editable variant where the existing rows
//  become TextFields bound to ViewModel draft intents. The View never
//  owns a second copy of the draft.
//
//  Recovery action: 重拍 returns to Scanner via the existing retake
//  path; from manualEditing it discards the draft.
//  NO Save button, NO BusinessCard creation, NO Repository write.
//
//  Raw OCR preservation: StructuredRecognitionResult.ocrResult is
//  carried in state; the draft keeps its immutable `source` result,
//  so rawText stays intact and never displayed as editable content.
//

import SwiftUI

struct RecognitionView: View {

    let viewModel: ScanViewModel

    /// Per-field UI focus for the editing form. UI-local focus only —
    /// NOT business state; the draft itself lives solely in the
    /// ViewModel (one state, one owner).
    @FocusState private var focusedField: EditingField?

    /// Stable identity of whichever field row is being edited.
    private enum EditingField: Hashable {
        case name
        case company
        case jobTitle
        case website
        case address
        case phone(Int)
        case email(Int)
    }

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
            case .manualEditing(let draft):
                editingContent(draft)
            case .failed(let error):
                failedContent(error)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Processing

    private func processingContent(_ crop: CardCropResult) -> some View {
        VStack(spacing: 0) {
            topBar(showEditButton: false)
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
                topBar(showEditButton: true)
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

    // MARK: - P05 Manual editing form (T11)

    /// S05 manualEditing variant of the P05 form. Layout, row order,
    /// fixed/data-driven row policy and row metrics are identical to
    /// the read-only form; only the value region switches from Text
    /// to TextField and the state marker changes. The website row
    /// exists while editing exactly when it existed on the source
    /// form (a cleared website keeps its row but projects nil; adding
    /// brand-new fields is a later increment).
    private func editingContent(_ draft: RecognitionDraft) -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topBar(showEditButton: false)
                cropImage(draft.source.ocrResult.cropResult.processedImageData)
                    .frame(height: proxy.size.height * Self.imageFraction)

                ScrollView {
                    VStack(spacing: 0) {
                        stateAccessibility(marker: "scan-recognition-manual-editing")
                        editableRow(
                            label: "姓名",
                            text: draftBinding(get: { $0.name }, set: { viewModel.updateDraftName($0) }),
                            focus: .name,
                            id: "scan-edit-name"
                        )
                        editingPhoneRows(draft.phones)
                        editingEmailRows(draft.emails)
                        editableRow(
                            label: "公司",
                            text: draftBinding(get: { $0.company }, set: { viewModel.updateDraftCompany($0) }),
                            focus: .company,
                            id: "scan-edit-company"
                        )
                        editableRow(
                            label: "职位",
                            text: draftBinding(get: { $0.jobTitle }, set: { viewModel.updateDraftJobTitle($0) }),
                            focus: .jobTitle,
                            id: "scan-edit-job-title"
                        )
                        // Website row existence stays driven by the
                        // SOURCE form: only a field that was present on
                        // P05 can be corrected here (§11).
                        if draft.source.fields.website != nil {
                            editableRow(
                                label: "首页",
                                text: draftBinding(get: { $0.website }, set: { viewModel.updateDraftWebsite($0) }),
                                focus: .website,
                                id: "scan-edit-website"
                            )
                        }
                        editableRow(
                            label: "公司地址",
                            text: draftBinding(get: { $0.address }, set: { viewModel.updateDraftAddress($0) }),
                            focus: .address,
                            id: "scan-edit-address"
                        )
                    }
                }
            }
        }
    }

    /// Builds a Binding for a draft scalar without the View holding
    /// the draft: get reads the current manualEditing draft (empty
    /// string in any non-editing state), set routes through the
    /// owning ViewModel intent.
    private func draftBinding(
        get: @escaping (RecognitionDraft) -> String,
        set: @escaping (String) -> Void
    ) -> Binding<String> {
        Binding(
            get: {
                guard case .manualEditing(let draft) = viewModel.recognition else { return "" }
                return get(draft)
            },
            set: { set($0) }
        )
    }

    /// Label + editable value row matching the read-only row metrics.
    /// The TextField carries the stable edit accessibility id; a
    /// trailing clear (×) button appears while the row is focused and
    /// non-empty, mirroring REF-edit-02.
    private func editableRow(
        label: String,
        text: Binding<String>,
        focus: EditingField,
        id: String
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(Self.labelColor)
                    .frame(width: 72, alignment: .leading)
                TextField("", text: text)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .tint(Self.recognitionBlue)
                    .focused($focusedField, equals: focus)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier(id)
                if focusedField == focus && !text.wrappedValue.isEmpty {
                    Button {
                        text.wrappedValue = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(white: 0.55))
                    }
                    .frame(width: 30, height: 30)
                    .accessibilityLabel("清除")
                }
            }
            .frame(height: 48)
            .padding(.horizontal, 16)

            Divider()
                .background(Self.separatorColor)
                .padding(.leading, 100)
        }
        .accessibilityElement(children: .contain)
    }

    /// Editable phone rows preserving stored order and kind;
    /// accessibility ids reuse the per-kind indexing of the
    /// read-only rows (`scan-edit-mobile-0`, …).
    private func editingPhoneRows(_ phones: [RecognitionDraft.PhoneField]) -> some View {
        ForEach(Array(phones.enumerated()), id: \.element.id) { index, phone in
            let (label, baseID) = phoneKindLabel(phone.kind)
            let kindIndex = phones[0..<index].filter { $0.kind == phone.kind }.count
            editableRow(
                label: label,
                text: draftBinding(
                    get: { $0.phones.first(where: { $0.id == phone.id })?.value ?? "" },
                    set: { viewModel.updateDraftPhone(id: phone.id, value: $0) }
                ),
                focus: .phone(phone.id),
                id: "\(baseID.replacingOccurrences(of: "scan-field", with: "scan-edit"))-\(kindIndex)"
            )
        }
    }

    /// Editable email rows preserving stored order with indexed ids.
    private func editingEmailRows(_ emails: [RecognitionDraft.EmailField]) -> some View {
        ForEach(Array(emails.enumerated()), id: \.element.id) { _, email in
            editableRow(
                label: "工作邮箱",
                text: draftBinding(
                    get: { $0.emails.first(where: { $0.id == email.id })?.value ?? "" },
                    set: { viewModel.updateDraftEmail(id: email.id, value: $0) }
                ),
                focus: .email(email.id),
                id: "scan-edit-email-\(email.id)"
            )
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

    /// Recognition chrome. The read-only settled forms show a trailing
    /// 编辑 entry into S05 manualEditing (T11); processing/failure and
    /// the editing form itself show only 重拍 (which discards the
    /// in-progress draft and returns to the Scanner).
    private func topBar(showEditButton: Bool) -> some View {
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
            if showEditButton {
                Button {
                    viewModel.beginManualEditing()
                } label: {
                    Text("编辑")
                        .font(.system(size: 17))
                        .foregroundStyle(Self.recognitionBlue)
                        .frame(minWidth: 56, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("scan-recognition-edit")
            }
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
