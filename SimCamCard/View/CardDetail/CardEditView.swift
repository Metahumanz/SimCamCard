//
//  CardEditView.swift
//  SimCamCard
//
//  T14 Existing-Card Editing page (编辑名片), presented from Card Detail.
//
//  Evidence: evidence/screenshots/REF-edit-01-before-change.png,
//            evidence/screenshots/REF-edit-02-after-title-change.png
//
//  Reference observations:
//   - Nav bar: 取消 (leading) | 编辑名片 (title) | 保存 (trailing, blue).
//   - Field order (domain-supported subset): 姓名; one row per existing
//     phone with its kind label (手机 / 工作电话 / 传真 / 其他); one 工作邮箱
//     row per existing email; 公司; 职位; 首页; 公司地址.
//   - Every scalar row is ALWAYS present while editing: a missing saved
//     scalar (nil → "") can be filled in naturally (T14 brief §20).
//   - A focused non-empty row shows a trailing clear (×) affordance
//     (REF-edit-02 职位 row).
//   - Saving returns to the Detail in place, which immediately displays
//     the corrected title; Cancel discards the draft.
//
//  Reference-only surface deliberately NOT built (no Domain fields /
//  deferred increments): the card-image preview strip, 部门 rows, the
//  second company block (Shanghai Zhiyun Tech Co., Ltd. / Latin fields),
//  添加电话 / 添加邮箱 / 添加URL / 添加地址 / 添加公司信息 / 添加更多信息 /
//  添加背面 row adders, the pinyin sort-name row, phone kind editing, and
//  phone/email row deletion. T14 edits EXISTING values only.
//
//  State ownership: the BusinessCardEditDraft lives solely in
//  CardDetailViewModel; every TextField Binding routes through a ViewModel
//  intent. This View owns no editable copy (focus is UI-local only).
//

import SwiftUI

struct CardEditView: View {

    let viewModel: CardDetailViewModel

    @Environment(\.dismiss) private var dismiss

    /// UI-local focus only — NOT business state; the draft lives solely
    /// in the ViewModel (one state, one owner).
    @FocusState private var focusedField: FocusedField?

    /// Stable identity of whichever field row is focused.
    private enum FocusedField: Hashable {
        case name
        case company
        case jobTitle
        case website
        case address
        case phone(UUID)
        case email(Int)
    }

    private static let labelColor = Color(red: 0.0, green: 0.50, blue: 0.90)
    private static let separatorColor = Color(white: 0.18)

    var body: some View {
        NavigationStack {
            List {
                Section {
                    editRow(
                        label: "姓名",
                        text: binding(get: { $0.name }, set: viewModel.updateName),
                        focus: .name,
                        id: "card-edit-name"
                    )
                }

                Section {
                    ForEach(currentDraft.phones) { phone in
                        editRow(
                            label: Self.phoneLabel(phone.kind),
                            text: binding(
                                get: { draft in
                                    draft.phones.first { $0.id == phone.id }?.value ?? ""
                                },
                                set: { viewModel.updatePhone(id: phone.id, value: $0) }
                            ),
                            focus: .phone(phone.id),
                            id: "card-edit-phone-\(phone.id.uuidString)"
                        )
                    }

                    ForEach(Array(currentDraft.emails.enumerated()), id: \.offset) { index, _ in
                        editRow(
                            label: "工作邮箱",
                            text: binding(
                                get: { $0.emails.indices.contains(index) ? $0.emails[index] : "" },
                                set: { viewModel.updateEmail(index: index, value: $0) }
                            ),
                            focus: .email(index),
                            id: "card-edit-email-\(index)"
                        )
                    }
                }

                Section {
                    editRow(
                        label: "公司",
                        text: binding(get: { $0.company }, set: viewModel.updateCompany),
                        focus: .company,
                        id: "card-edit-company"
                    )
                    editRow(
                        label: "职位",
                        text: binding(get: { $0.jobTitle }, set: viewModel.updateJobTitle),
                        focus: .jobTitle,
                        id: "card-edit-job-title"
                    )
                    editRow(
                        label: "首页",
                        text: binding(get: { $0.website }, set: viewModel.updateWebsite),
                        focus: .website,
                        id: "card-edit-website"
                    )
                    editRow(
                        label: "公司地址",
                        text: binding(get: { $0.address }, set: viewModel.updateAddress),
                        focus: .address,
                        id: "card-edit-address"
                    )
                }
            }
            .accessibilityIdentifier("card-edit")
            .navigationTitle("编辑名片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                    .accessibilityIdentifier("card-edit-cancel")
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        HStack(spacing: 6) {
                            ProgressView()
                            Text("保存中…")
                        }
                        .accessibilityIdentifier("card-edit-saving")
                    } else {
                        Button("保存") {
                            Task { await viewModel.saveEdits() }
                        }
                        .accessibilityIdentifier("card-edit-save")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        // The save success transition moves editState back to .viewing;
        // dismiss back to the (already updated) Detail.
        .onChange(of: viewModel.editState) { _, newValue in
            if case .viewing = newValue {
                dismiss()
            }
        }
        .interactiveDismissDisabled(isSaving)
    }

    // MARK: - State access

    /// The live draft. The sheet is only visible while editing/saving;
    /// a fallback draft keeps getters valid during the dismiss transition.
    private var currentDraft: BusinessCardEditDraft {
        switch viewModel.editState {
        case .editing(let draft), .saving(let draft):
            return draft
        case .viewing:
            return BusinessCardEditDraft(source: viewModel.card)
        }
    }

    private var isSaving: Bool {
        if case .saving = viewModel.editState { return true }
        return false
    }

    // MARK: - Rows & bindings

    private func binding(
        get: @escaping (BusinessCardEditDraft) -> String,
        set: @escaping (String) -> Void
    ) -> Binding<String> {
        Binding(
            get: { get(currentDraft) },
            set: { set($0) }
        )
    }

    /// Label + TextField row matching the Reference grouped layout. The
    /// stable accessibility id is on the TextField. A trailing clear (×)
    /// button appears while the row is focused and non-empty
    /// (REF-edit-02).
    private func editRow(
        label: String,
        text: Binding<String>,
        focus: FocusedField,
        id: String
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Self.labelColor)
                .frame(width: 72, alignment: .leading)
            TextField("", text: text)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(Self.labelColor)
                .focused($focusedField, equals: focus)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .disabled(isSaving)
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
        .listRowBackground(Color(white: 0.08))
        .listRowSeparatorTint(Self.separatorColor)
    }

    private static func phoneLabel(_ kind: PhoneNumber.Kind) -> String {
        switch kind {
        case .mobile: "手机"
        case .office: "工作电话"
        case .fax: "传真"
        case .other: "其他"
        }
    }
}
