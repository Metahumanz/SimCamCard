//
//  CardDetailView.swift
//  SimCamCard
//
//  Read-only Card Detail page (P07, S06 detailCollapsed / T13 Detail).
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail ("View structured data")
//   - spec/state-inventory.md S06 detailCollapsed
//   - spec/reference-tests.md T13 Detail ("Saved structured fields are
//     visible in detail view.")
//   - spec/data-model.md §Multi-value observation, §Missing-field rule
//   - Evidence: evidence/screenshots/REF-detail-01-collapsed.png,
//     evidence/screenshots/REF-detail-03-after-edit-expanded.png
//
//  Evidence → element mapping (see ai/changes.md for the full table):
//   - Header name / title / company → header VStack (one Text per present
//     field; nil fields are hidden, never fabricated)
//   - phones[] (手机/工作电话/传真/其他) → one CardDetailFieldRow EACH
//   - emails[] (邮箱)                → one CardDetailFieldRow EACH
//   - website (首页)                 → single CardDetailFieldRow if present
//   - address (公司地址)             → single CardDetailFieldRow if present
//
//  Collapsed/expanded decision (recorded ambiguity):
//   - The Reference collapsed state (REF-detail-01) shows only the first
//     phone behind a 「展开」 affordance; the expanded state
//     (REF-detail-03) shows every phone with its kind label.
//   - The Increment 5 brief explicitly requires multi-value fields
//     (phones[]/emails[]) to be displayed without loss. This skeleton
//     therefore renders ALL structured fields directly (field content
//     equivalent to the expanded evidence) and does NOT implement the
//     展开/收起 interaction. T13 behavioral acceptance is unaffected;
//     the collapse interaction remains a Reference UI fidelity gap.
//
//  Deliberately NOT implemented this increment (no behaviorless control
//  farm): Edit (T14), Group (T16), Notes (P10), Delete (T17), Export
//  (T19), phone/email/web invocation (no tel:/URL wiring), favorite star,
//  more menu, the 电话/地址/备注/编辑 action grid, the 未分组 group row,
//  the notes row, the bottom 存入通讯录/递名片/分享名片 bar, avatar, card
//  image (Domain holds String references only — no fabricated thumbnail),
//  and 展开/收起. No "Coming soon" / "Not implemented" text.
//
//  State ownership:
//   - CardDetailViewModel owns the displayed BusinessCard value.
//   - This View is stateless and reads domain fields directly (no DTO).
//

import SwiftUI

struct CardDetailView: View {

    let viewModel: CardDetailViewModel

    private var card: BusinessCard { viewModel.card }

    var body: some View {
        List {
            // MARK: Identity header
            //
            // Week 2 scaffold: plain stacked texts. The Reference dark
            // header card, avatar and card-image strip are fidelity gaps
            // (no real image pipeline; avatar styling not replicated).
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
// The Detail receives a complete BusinessCard value (same ownership path
// as real navigation). No repository or async loading is needed here —
// the value is passed straight into CardDetailViewModel, exactly as
// CardHolderView's navigationDestination does.

#Preview("Card Detail — full bilingual card (001)") {
    NavigationStack {
        CardDetailView(
            viewModel: CardDetailViewModel(card: MockBusinessCards.card001)
        )
    }
}

#Preview("Card Detail — minimal card (004)") {
    NavigationStack {
        CardDetailView(
            viewModel: CardDetailViewModel(card: MockBusinessCards.card004)
        )
    }
}

#endif
