//
//  BusinessCardRow.swift
//  SimCamCard
//
//  Card Holder list row for a single BusinessCard (P01 populated state).
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder (populated list)
//   - spec/state-inventory.md S01 populated (one or more cards shown)
//   - spec/reference-tests.md T13 Detail (selecting a row opens Detail)
//   - Evidence: evidence/screenshots/REF-card-holder-02-after-save.png
//
//  Evidence-supported fields rendered (Week 2 scaffold):
//   - Name (primary, semibold)
//   - Job title · Company (secondary line)
//
//  As of Week 2 Increment 5 this row is embedded in a NavigationLink by
//  CardHolderView; tapping it pushes the read-only Card Detail page.
//
//  Deliberately still omitted:
//   - Thumbnail — Domain Model has String image references only; no real
//     image asset is loaded (capture pipeline deferred). Rendering a
//     placeholder would be invented UI; recorded as ambiguity.
//   - Three-dot per-row actions menu — per-row actions / context menu /
//     delete deferred.
//   - Favorites / avatar / company logo / swipe actions / context menus /
//     online enrichment — deferred.
//
//  State ownership:
//   - This View is stateless. The BusinessCard is passed in; the View
//     does not own or mutate a [BusinessCard] source of truth.
//

import SwiftUI

struct BusinessCardRow: View {

    let card: BusinessCard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.name ?? "未命名")
                .font(.body.weight(.semibold))

            // Secondary line: job title · company. Skipped entirely when
            // both are nil (Card 004 minimal card → only name shown).
            if card.jobTitle != nil || card.company != nil {
                Text(secondaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    /// Composes the secondary line as "jobTitle · company", omitting
    /// whichever structured field is nil. Both present → joined by " · ".
    /// One present → shown alone. Both nil → empty (caller skips line).
    private var secondaryLine: String {
        [card.jobTitle, card.company]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

#if DEBUG

#Preview("BusinessCardRow — full bilingual card") {
    List {
        BusinessCardRow(card: MockBusinessCards.card001)
            .accessibilityIdentifier("card-row-\(MockBusinessCards.card001.id.uuidString)")
    }
    .listStyle(.plain)
}

#Preview("BusinessCardRow — missing website (Card 002)") {
    List {
        BusinessCardRow(card: MockBusinessCards.card002)
            .accessibilityIdentifier("card-row-\(MockBusinessCards.card002.id.uuidString)")
    }
    .listStyle(.plain)
}

#Preview("BusinessCardRow — minimal card (Card 004)") {
    List {
        BusinessCardRow(card: MockBusinessCards.card004)
            .accessibilityIdentifier("card-row-\(MockBusinessCards.card004.id.uuidString)")
    }
    .listStyle(.plain)
}

#endif
