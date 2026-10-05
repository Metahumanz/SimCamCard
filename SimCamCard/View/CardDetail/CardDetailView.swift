//
//  CardDetailView.swift
//  SimCamCard
//
//  Card Detail page (P07, S06 detailCollapsed / T13 Detail) with the
//  T14 Existing-Card Editing entry, the P10 Notes entry, and the T17
//  Delete flow.
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail ("View structured data")
//   - spec/state-inventory.md S06 detailCollapsed, S06 `deleted`, S01
//     list updates immediately after delete
//   - spec/reference-tests.md T13 Detail ("Saved structured fields are
//     visible in detail view."), T14 Existing-Card Editing ("edited
//     title → stored BusinessCard changes → Detail displays corrected
//     title"), T17 Delete ("Confirmation precedes delete; card
//     disappears afterward.")
//   - spec/data-model.md §Multi-value observation, §Missing-field rule
//   - Evidence: evidence/screenshots/REF-detail-01-collapsed.png,
//     evidence/screenshots/REF-detail-03-after-edit-expanded.png,
//     evidence/screenshots/REF-detail-04-more-actions.png,
//     evidence/screenshots/REF-delete-01-confirmation.png,
//     evidence/screenshots/REF-card-holder-01-empty.png,
//     evidence/screenshots/REF-edit-01-before-change.png,
//     evidence/screenshots/REF-edit-02-after-title-change.png
//
//  Evidence → element mapping (see ai/changes.md for the full table):
//   - Header name / title / company → header VStack (one Text per present
//     field; nil fields are hidden, never fabricated)
//   - phones[] (手机/工作电话/传真/其他) → one CardDetailFieldRow EACH
//   - emails[] (邮箱)                → one CardDetailFieldRow EACH
//   - website (首页)                 → single CardDetailFieldRow if present
//   - address (公司地址)             → single CardDetailFieldRow if present
//   - P10 Notes entry                → green circular note.text 备注
//     action (3rd slot) plus a 备注 row in the more-actions dialog,
//     both pushing CardNotesView.
//   - T14 Edit entry                 → teal circular pencil 编辑 action
//     at the Reference action-strip position (4th slot), presenting
//     CardEditView; the deferred 电话/地址 actions are not faked.
//
//  Collapsed/expanded decision (recorded ambiguity):
//   - The Reference collapsed state (REF-detail-01) shows only the first
//     phone behind a 「展开」 affordance; the expanded state
//     (REF-detail-03) shows every phone with its kind label.
//   - The earlier brief explicitly requires multi-value fields
//     (phones[]/emails[]) to be displayed without loss. This view
//     therefore renders ALL structured fields directly (field content
//     equivalent to the expanded evidence) and does NOT implement the
//     展开/收起 interaction. T13 behavioral acceptance is unaffected;
//     the collapse interaction remains a Reference UI fidelity gap.
//
//  T14 closure: CardEditView saves through CardDetailViewModel, which
//  replaces the same-id entity in the shared Repository and updates its
//  own `card` in place — the corrected title is visible immediately when
//  the sheet dismisses, without returning to the Holder. The Holder
//  reloads through its existing onAppear path when the user goes back.
//
//  P10 closure: both 备注 entries push CardNotesView with the SAME view
//  model, so a saved note appends to this same BusinessCard aggregate
//  (repository.save same-id replace) and is visible immediately; the
//  pushed page pops back to an already-consistent Detail. The
//  Reference's inline notes-summary row (「备注: 2026-09-28 拍名片保存」)
//  is not implemented — it previews a typed system save record that the
//  frozen CardNote domain cannot represent (fidelity difference).
//
//  Deliberately NOT implemented: Export (T19), phone/email/web
//  invocation (no tel:/URL wiring), favorite star, the deferred
//  more-sheet entries (保存到通讯录/分组/提醒/邀请使用名片), the
//  电话/地址 action-strip entries, the 未分组 group row, the inline
//  notes-summary row, the bottom 存入通讯录/递名片/分享名片 bar,
//  avatar, card image (Domain holds String references only), and
//  展开/收起.
//  No "Coming soon" / "Not implemented" text.
//
//  T17 closure: the trailing ••• (card-detail-more) opens a native
//  confirmationDialog whose live actions are 备注 (P10) and 删除
//  (card-detail-delete); 删除 presents the native 「提示」 alert.
//  Confirm runs repository delete
//  → Holder onDeleted reload → dismiss; 取消 leaves the card untouched.
//

import SwiftUI

struct CardDetailView: View {

    let viewModel: CardDetailViewModel

    /// T17: invoked AFTER the shared repository has deleted the card and
    /// BEFORE this Detail is dismissed. The Holder reloads its cards +
    /// groups snapshot here, so the list is already correct when the pop
    /// completes (not relying on onAppear timing). Production always
    /// supplies a real reload closure; Previews pass a no-op.
    let onDeleted: @MainActor () async -> Void

    @Environment(\.dismiss) private var dismiss

    /// Presents the Reference more-actions bottom surface (•••).
    @State private var showMoreActions = false

    /// Presents the native 「提示」 delete confirmation alert.
    @State private var showDeleteAlert = false

    /// Pushes the P10 Notes page (both the action-strip 备注 entry and
    /// the more-actions 备注 entry share this single pushed page).
    @State private var showNotes = false

    private var card: BusinessCard { viewModel.card }

    var body: some View {
        List {
            // MARK: Identity header
            //
            // Plain stacked texts. The Reference dark header card and
            // avatar are fidelity gaps.
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.name ?? "未命名")
                        .font(.title2.weight(.bold))
                        .accessibilityIdentifier("card-detail-name")

                    if let jobTitle = card.jobTitle {
                        Text(jobTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("card-detail-job-title")
                    }

                    if let company = card.company {
                        Text(company)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("card-detail-company")
                    }
                }
                .padding(.vertical, 6)
            }

            // MARK: Action strip
            //
            // T14/P10: the Reference places four circular actions under
            // the header (电话 / 地址 / 备注 / 编辑). 备注 and 编辑 are
            // functional; they occupy the Reference's trailing pair
            // (3rd/4th slots). The deferred 电话/地址 actions are
            // intentionally not rendered as dead controls.
            //
            // Both buttons MUST carry an explicit PlainButtonStyle.
            // With the List-row default `.automatic` style, multiple
            // Buttons sharing one List row are each treated as a row
            // action: a single tap then runs EVERY button's action in
            // the row (observed: tapping 备注 also opened the edit
            // sheet). `.plain` makes each Button a standalone control.
            Section {
                HStack(spacing: 28) {
                    Spacer()

                    Button {
                        showNotes = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color(red: 0.55, green: 0.76, blue: 0.20))
                                .clipShape(Circle())
                            Text("备注")
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundStyle(.primary)
                    .buttonStyle(.plain)
                    .accessibilityLabel("备注")
                    .accessibilityIdentifier("card-detail-notes")

                    Button {
                        viewModel.beginEditing()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color(red: 0.10, green: 0.62, blue: 0.55))
                                .clipShape(Circle())
                            Text("编辑")
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundStyle(.primary)
                    .buttonStyle(.plain)
                    .accessibilityLabel("编辑")
                    .accessibilityIdentifier("card-detail-edit")
                }
                .padding(.vertical, 4)
            }

            // MARK: Structured fields
            //
            // Multi-value collections are rendered one row per element —
            // never collapsed into single mobile/email properties.
            Section {
                ForEach(card.phones) { phone in
                    CardDetailFieldRow(
                        systemImage: "phone",
                        value: phone.value,
                        label: phone.kind.detailLabel
                    )
                    .accessibilityIdentifier(
                        "card-detail-phone-\(phone.id.uuidString)"
                    )
                }

                ForEach(Array(card.emails.enumerated()), id: \.offset) { index, email in
                    CardDetailFieldRow(
                        systemImage: "envelope",
                        value: email,
                        label: "邮箱"
                    )
                    .accessibilityIdentifier("card-detail-email-\(index)")
                }

                if let website = card.website {
                    CardDetailFieldRow(
                        systemImage: "globe",
                        value: website,
                        label: "首页"
                    )
                    .accessibilityIdentifier("card-detail-website")
                }

                if let address = card.address {
                    CardDetailFieldRow(
                        systemImage: "mappin.and.ellipse",
                        value: address,
                        label: "公司地址"
                    )
                    .accessibilityIdentifier("card-detail-address")
                }
            }
        }
        .accessibilityIdentifier("card-detail")
        .navigationTitle("名片详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // T17/P10 Reference entries (REF-detail-04): the trailing •••
            // opens the native more-actions surface. 备注 pushes the
            // Notes page and 删除 runs the T17 flow; the Reference's
            // other grid entries (保存到通讯录/分组/提醒/邀请) are
            // deferred and never faked as dead buttons.
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showMoreActions = true
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("更多操作")
                .accessibilityIdentifier("card-detail-more")
            }
        }
        .confirmationDialog(
            "更多操作",
            isPresented: $showMoreActions,
            titleVisibility: .visible
        ) {
            // 备注 (P10): push the same Notes page as the action-strip
            // entry (REF-detail-04 row 2).
            Button {
                showNotes = true
            } label: {
                Label("备注", systemImage: "note.text")
            }
            .accessibilityIdentifier("card-detail-more-notes")

            // 删除 → request confirmation (T17). The destructive action
            // moves the ViewModel to .confirming and presents the alert.
            Button(role: .destructive) {
                viewModel.requestDelete()
                showDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
            .accessibilityIdentifier("card-detail-delete")

            Button("取消", role: .cancel) {}
        }
        .alert("提示", isPresented: $showDeleteAlert) {
            // 取消 (T17): confirmation dismissed, card and repository
            // untouched; the Detail stays on screen.
            Button("取消", role: .cancel) {
                viewModel.cancelDelete()
            }
            .accessibilityIdentifier("card-delete-cancel")

            // 删除名片 (T17): hard-delete through the repository, then let
            // the Holder reload, and only THEN dismiss the Detail. The
            // ordering is strictly repository delete → reload → dismiss.
            Button("删除名片", role: .destructive) {
                Task {
                    if await viewModel.confirmDelete() {
                        await onDeleted()
                        dismiss()
                    }
                }
            }
            .accessibilityIdentifier("card-delete-confirm")
        } message: {
            Text("删除未同步名片将无法恢复，请确认是否要删除？")
        }
        .sheet(isPresented: editingSheetBinding) {
            CardEditView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showNotes) {
            CardNotesView(viewModel: viewModel)
        }
    }

    /// The sheet is presented while a draft exists (editing/saving).
    /// A user-driven dismissal (swipe down) maps to Cancel semantics:
    /// the draft is discarded and nothing is persisted.
    private var editingSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.editState != .viewing },
            set: { presented in
                if !presented {
                    viewModel.cancelEditing()
                }
            }
        )
    }
}

// MARK: - Phone kind presentation labels
//
// Chinese labels observed in the Reference Detail evidence
// (REF-detail-02 phone picker / REF-detail-03 expanded rows).
// This is a VIEW-LAYER mapping; the Domain PhoneNumber.Kind stays
// UI-independent (no Chinese strings in the Model layer).

private extension PhoneNumber.Kind {

    var detailLabel: String {
        switch self {
        case .mobile: "手机"
        case .office: "工作电话"
        case .fax: "传真"
        case .other: "其他"
        }
    }
}

#if DEBUG

// MARK: - SwiftUI Previews
//
// The Detail receives a complete BusinessCard value plus a repository
// seeded with it, exactly as CardHolderView's navigationDestination
// constructs it (T14 edits save into that repository).

#Preview("Card Detail — full bilingual card (001)") {
    NavigationStack {
        CardDetailView(
            viewModel: CardDetailViewModel(
                card: MockBusinessCards.card001,
                repository: InMemoryBusinessCardRepository(
                    initialCards: MockBusinessCards.all
                )
            ),
            onDeleted: {}
        )
    }
}

#Preview("Card Detail — minimal card (004)") {
    NavigationStack {
        CardDetailView(
            viewModel: CardDetailViewModel(
                card: MockBusinessCards.card004,
                repository: InMemoryBusinessCardRepository(
                    initialCards: [MockBusinessCards.card004]
                )
            ),
            onDeleted: {}
        )
    }
}

#endif
