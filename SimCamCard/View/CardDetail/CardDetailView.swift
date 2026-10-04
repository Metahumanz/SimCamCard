//
//  CardDetailView.swift
//  SimCamCard
//
//  Card Detail page (P07, S06 detailCollapsed / T13 Detail) with the
//  T14 Existing-Card Editing entry.
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail ("View structured data")
//   - spec/state-inventory.md S06 detailCollapsed
//   - spec/reference-tests.md T13 Detail ("Saved structured fields are
//     visible in detail view."), T14 Existing-Card Editing ("edited
//     title → stored BusinessCard changes → Detail displays corrected
//     title")
//   - spec/data-model.md §Multi-value observation, §Missing-field rule
//   - Evidence: evidence/screenshots/REF-detail-01-collapsed.png,
//     evidence/screenshots/REF-detail-03-after-edit-expanded.png,
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
//   - T14 Edit entry                 → teal circular pencil 编辑 action at
//     the Reference action-strip position (4th slot; the deferred
//     电话/地址/备注 actions are not faked), presenting CardEditView.
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
//  Deliberately NOT implemented: Group (T16), Notes (P10), Delete (T17),
//  Export (T19), phone/email/web invocation (no tel:/URL wiring),
//  favorite star, the ••• more sheet, the 电话/地址/备注 actions, the
//  未分组 group row, the notes row, the bottom 存入通讯录/递名片/分享名片
//  bar, avatar, card image (Domain holds String references only), and
//  展开/收起. No "Coming soon" / "Not implemented" text.
//

import SwiftUI

struct CardDetailView: View {

    let viewModel: CardDetailViewModel

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
            // T14: the Reference places four circular actions under the
            // header (电话 / 地址 / 备注 / 编辑). Only 编辑 is functional
            // in this increment; it occupies the Reference's trailing
            // position. The deferred actions are intentionally not
            // rendered as dead controls.
            Section {
                HStack {
                    Spacer()
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
        .sheet(isPresented: editingSheetBinding) {
            CardEditView(viewModel: viewModel)
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
            )
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
            )
        )
    }
}

#endif
