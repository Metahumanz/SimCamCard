//
//  CardHolderView.swift
//  SimCamCard
//
//  Root content view for the Card Holder page (P01).
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder (empty / populated;
//     main exit: Detail)
//   - spec/state-inventory.md S01 empty / populated
//   - spec/reference-tests.md T01 Empty Card Holder / T13 Detail
//     (selecting a card opens Card Detail)
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
//   - Card row (populated)         → BusinessCardRow inside a NavigationLink
//                                   to AppRoute.cardDetail(card.id)
//
//  Navigation (Week 2 Increment 5):
//   - Rows are NavigationLinks carrying the card's stable UUID
//     (AppRoute.cardDetail(UUID)) — never a row index; Repository
//     ordering remains unspecified.
//   - `navigationDestination` resolves the UUID against the cards this
//     holder already owns and constructs CardDetailViewModel with the
//     full BusinessCard value (no second repository fetch).
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
//     and populated / detail UI tests can locate and tap specific rows
//     by stable id. UI tests verify membership only, never row position.
//
//  T02 scanner navigation, T15 Search behavior and T16 Group behavior
//  remain deferred. The toolbar "+" is a non-triggering element.
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
                    NavigationLink(value: AppRoute.cardDetail(card.id)) {
                        BusinessCardRow(card: card)
                    }
                    .accessibilityIdentifier("card-row-\(card.id.uuidString)")
                }
            }
        }
        .navigationTitle("名片夹")
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .cardDetail(let id):
                // Resolve the stable id to the complete aggregate this
                // holder already owns. UUID selection (not index) keeps
                // navigation independent of unspecified repository order.
                if let card = viewModel.cards.first(where: { $0.id == id }) {
                    CardDetailView(viewModel: CardDetailViewModel(card: card))
                }
                // A missing id cannot occur via holder row taps; an empty
                // fallback is sufficient for the typed initializer.
            }
        }
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
// `navigationTitle` / `toolbar` / `navigationDestination` rely on the
// enclosing navigation container environment.
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
