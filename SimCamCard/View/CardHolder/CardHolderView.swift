//
//  CardHolderView.swift
//  SimCamCard
//
//  Root content view for the Card Holder page (P01).
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder (empty state)
//   - spec/state-inventory.md S01 empty (zero saved cards, scan entry
//     remains available)
//   - spec/reference-tests.md T01 Empty Card Holder
//   - Evidence: evidence/screenshots/REF-card-holder-01-empty.png
//
//  UI evidence → View element mapping (see ai/changes.md for full table):
//   - "名片夹" page identity      → navigationTitle("名片夹")
//   - "+" scan entry (header)     → toolbar trailing Button (non-triggering,
//                                   Week 2 scaffold — NOT a verified replica
//                                   of the Reference header "+" button)
//   - "名片 (0张)" count indicator → ContentUnavailableView title (Week 2
//                                   scaffold — NOT a verified replica of the
//                                   Reference empty-state visual)
//   - Search bar                   → in-scope UI, behavior deferred to a
//                                   later increment (NOT permanently excluded)
//   - Quick Action Grid            → Group Management = in scope, deferred;
//                                   Contact Map / Analytics = excluded
//   - Tutorial card                → excluded (promotional content)
//   - Bottom tab bar               → excluded (switches to excluded pages)
//
//  Increment 3 does NOT implement T02 scanner navigation. The "+" button
//  is a minimal non-triggering UI element — it does not navigate to a
//  scanner and does not display "Coming soon" / "Not implemented".
//

import SwiftUI

struct CardHolderView: View {

    /// The sole state owner for Card Holder card data.
    /// The View reads `viewModel.cards` directly; it does NOT hold its
    /// own `[BusinessCard]`.
    let viewModel: CardHolderViewModel

    var body: some View {
        Group {
            if viewModel.cards.isEmpty {
                ContentUnavailableView {
                    Label("名片 (0张)", systemImage: "rectangle.stack")
                }
                .accessibilityIdentifier("card-holder-empty")
            } else {
                List(viewModel.cards) { card in
                    Text(card.name ?? "未命名")
                }
            }
        }
        .navigationTitle("名片夹")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Scan entry CTA — visual only this increment.
                    // T02 Scanner navigation is deferred; do NOT navigate.
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("扫描")
            }
        }
    }
}
