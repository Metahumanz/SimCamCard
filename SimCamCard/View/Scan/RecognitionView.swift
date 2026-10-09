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
//
//  Week 4 Increment 4 (T12) adds Save. Both the read-only settled form
//  (编辑 + 保存 shown together) and the manualEditing form (保存) offer
//  Save: saving does NOT require entering Edit first. Save materializes
//  the current result (or the corrected draft) into a final
//  BusinessCard via BusinessCardMaterializer, persists the original +
//  processed image assets, writes to the repository and settles the
//  separate SaveState in .saveSucceeded → P06. P06 screen ownership
//  comes from saveState (S06) and takes priority over the S05 content,
//  which stays intact underneath until 拍下一张 discards the workflow.
//  P06 is a minimal-fidelity Save Result (REF-save-01): ✓名片保存成功
//  title, 完成 (pop back to the Holder, which reloads), a saved-card
//  summary strip, and 拍下一张 (retake into a fresh Scanner). The
//  Reference's 分组/备注/提醒/保存失败 grid, VIP invite, 企业简介 and
//  交换名片 are spec-excluded and not built.
//
//  Raw OCR preservation: StructuredRecognitionResult.ocrResult is
//  carried in state; the draft keeps its immutable `source` result,
//  so rawText stays intact and never displayed as editable content.
//

import SwiftUI

struct RecognitionView: View {

    let viewModel: ScanViewModel

    /// P06 完成 pops the Scanner back to the Card Holder via the
    /// enclosing NavigationStack (no custom navigation state).
    @Environment(\.dismiss) private var dismiss

    /// Per-field UI focus for the editing form. UI-local focus only —
    /// NOT business state; the draft itself lives solely in the
    /// ViewModel (one state, one owner).
    @FocusState private var focusedField: EditingField?

    /// P06 summary thumbnail bytes resolved from the ImageAssetStore via
    /// the saved card's real `processedImageReference`. UI-local
    /// presentation cache only — the Domain keeps String references and
    /// the store remains the single owner of the asset bytes.
    @State private var summaryThumbnail: Data?

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

            // S06 SaveState owns the screen once a save has settled:
            // P06 takes priority over the S05 content, which stays
            // intact underneath until 拍下一张 discards the workflow.
            if case .saveSucceeded(let card) = viewModel.saveState {
                saveSucceededContent(card)
            } else {
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
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Processing

    private func processingContent(_ crop: CardCropResult) -> some View {
        VStack(spacing: 0) {
            topBar(showEdit: false, showSave: false)
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
                topBar(showEdit: true, showSave: true)
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
                topBar(showEdit: false, showSave: true)
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
        // T20 (E06, §10): the failure fallback offers BOTH exits —
        // 重拍 returns to the Scanner for another capture, and 取消
        // leaves the whole scan flow directly back to the Holder.
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
            HStack(spacing: 28) {
                Button {
                    dismiss()
                } label: {
                    Text("取消")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(minWidth: 64, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("scan-recognition-cancel")
                Button {
                    Task { await viewModel.retake() }
                } label: {
                    Text("重拍")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Self.recognitionBlue)
                        .frame(minWidth: 64, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("scan-recognition-retake")
            }
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

    // MARK: - P06 Save Result (T12)

    /// Minimal-fidelity Save Result (REF-save-01): ✓名片保存成功 title,
    /// 完成 (pop back to the Holder, which reloads and lists the new
    /// card), a saved-card summary strip (real processed-image thumbnail
    /// + name / job title / company) and 拍下一张 (discard the saved
    /// workflow and return to a fresh Scanner). The Reference's
    /// 分组/备注/提醒/保存失败 grid, VIP invite, 企业简介 and 交换名片 are
    /// spec-excluded (spec/page-inventory.md P06) and not built.
    private func saveSucceededContent(_ card: BusinessCard) -> some View {
        VStack(spacing: 0) {
            // Title bar: centered ✓名片保存成功 + trailing 完成.
            ZStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                    Text("名片保存成功")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("完成")
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                            .frame(minWidth: 56, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("scan-save-done")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            // Saved-card summary strip: real thumbnail resolved from the
            // persisted image asset, then the saved structured fields.
            HStack(spacing: 12) {
                summaryThumbnailImage
                    .frame(width: 72, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .accessibilityIdentifier("scan-save-thumbnail")
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.name ?? "未命名")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("scan-save-name")
                    if let jobTitle = card.jobTitle {
                        Text(jobTitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    if let company = card.company {
                        Text(company)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Self.formBackground)
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("scan-save-summary")
            .task(id: card.id) {
                summaryThumbnail = await viewModel.imageData(
                    for: card.processedImageReference
                )
            }

            Spacer(minLength: 0)

            // 拍下一张: white capsule (交换名片 is spec-excluded).
            Button {
                Task { await viewModel.captureNextAfterSave() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera")
                        .font(.system(size: 17))
                    Text("拍下一张")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundStyle(Self.recognitionBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule().fill(.white))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
            .accessibilityIdentifier("scan-save-next")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("scan-save-success")
    }

    /// P06 strip thumbnail decoded from the stored asset bytes. An
    /// undecodable or missing asset renders a neutral dark slot (never
    /// a fabricated image) — the text summary still identifies the card.
    @ViewBuilder
    private var summaryThumbnailImage: some View {
        if let data = summaryThumbnail, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Self.separatorColor)
        }
    }

    // MARK: - Shared chrome

    /// Recognition chrome. 重拍 always discards the in-progress workflow
    /// and returns to the Scanner. Trailing actions are independent
    /// flags, NOT mutually exclusive:
    ///  - read-only settled forms: 编辑 entry into S05 manualEditing
    ///    AND direct 保存 — saving must not require Edit first (T12);
    ///  - manualEditing: 保存 only (编辑 already active);
    ///  - processing / failure: neither.
    private func topBar(showEdit: Bool, showSave: Bool) -> some View {
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
            if showEdit {
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
            if showSave {
                Button {
                    Task { await viewModel.saveCurrentCard() }
                } label: {
                    Text("保存")
                        .font(.system(size: 17))
                        .foregroundStyle(Self.recognitionBlue)
                        .frame(minWidth: 56, minHeight: 44)
                        .contentShape(Rectangle())
                }
                // T20 (E07): disabled while saving AND whenever the
                // current content has zero canonical contact fields
                // (the non-card empty result / an all-cleared draft) —
                // an empty result must never save a blank BusinessCard.
                .disabled(viewModel.isSaveInFlight || !viewModel.canSaveCurrentCard)
                .accessibilityIdentifier("scan-recognition-save")
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
