//
//  CardHolderView.swift
//  SimCamCard
//
//  Root content view for the Card Holder page (P01).
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder (empty / populated)
//   - spec/state-inventory.md S01 empty (zero saved cards, scan entry
//     remains available) / S01 populated (one or more cards shown)
//   - spec/reference-tests.md T01 Empty Card Holder / T12 Save (card
//     immediately appears in holder — repository-level prerequisite
//     verified by ViewModel loadCards path)
//   - Evidence: evidence/screenshots/REF-card-holder-01-empty.png,
//     evidence/screenshots/REF-card-holder-02-after-save.png
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
//   - Card row (populated)         → BusinessCardRow (Name + Title · Company);
//                                   Week 2 scaffold — no thumbnail, no
//                                   three-dot menu (deferred)
//
//  State ownership (one state, one owner):
//   - Repository = data source abstraction
//   - CardHolderViewModel = SOLE owner of `cards`
//   - CardHolderView = rendering + user intent; reads `viewModel.cards`
//     directly, does NOT hold its own [BusinessCard]
//
//  Card row accessibility:
//   - Each row carries `card-row-<UUID>` so T01 empty UI test can verify
//     NO card rows exist (NSPredicate identifier BEGINSWITH "card-row-"),
//     and populated UI tests can verify specific rows exist by stable id.
//   - UI tests verify membership only — Repository contract defines no
//     order, so no row-position assertions.
//
//  Increment 4 does NOT implement T02 scanner navigation. The "+" button
//  is a minimal non-triggering UI element — it does not navigate to a
//  scanner and does not display "Coming soon" / "Not implemented".
//  Increment 4 does NOT implement T13 Detail navigation — the list rows
//  are not tappable. T15 Search behavior and T16 Group behavior are
//  deferred.
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
                    BusinessCardRow(card: card)
                        .accessibilityIdentifier("card-row-\(card.id.uuidString)")
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

#if DEBUG

// MARK: - SwiftUI Previews
//
// Both Previews wrap CardHolderView in NavigationStack because
// `navigationTitle` / `toolbar` rely on the enclosing navigation
// container environment.
//
// Populated Preview uses the real Repository → CardHolderViewModel → View
// data path. The View never hardcodes a [BusinessCard] source of truth;
// it reads `viewModel.cards` like the production code does. The async
// `loadCards()` is triggered via a minimal `.task`; no fake ViewModel
// initializer is added to the production type.

#Preview("Empty Card Holder") {
    NavigationStack {
        CardHolderView(
            viewModel: CardHolderViewModel(
                repository: InMemoryBusinessCardRepository()
            )
        )
    }
}

#Preview("Populated Card Holder") {
    let viewModel = CardHolderViewModel(
        repository: InMemoryBusinessCardRepository(
            initialCards: MockBusinessCards.all
        )
    )
    return NavigationStack {
        CardHolderView(viewModel: viewModel)
            .task { await viewModel.loadCards() }
    }
}

#endif
