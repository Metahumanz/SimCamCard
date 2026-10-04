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
//   - "+" scan entry (header)     → toolbar trailing NavigationLink to
//                                   AppRoute.scan (T02 navigation, Week 2
//                                   Increment 6; NOT a verified replica of
//                                   the Reference header "+" button)
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
//  Week 2 Increment 6: the toolbar "+" is now a typed NavigationLink to
//  AppRoute.scan (T02 scan-entry navigation + Scanner UI shell). T15
//  Search behavior and T16 Group behavior remain deferred.
//

import SwiftUI

struct CardHolderView: View {

    /// The sole state owner for Card Holder card data.
    /// The View reads `viewModel.cards` directly; it does NOT hold its
    /// own `[BusinessCard]`.
    let viewModel: CardHolderViewModel

    /// Persistence dependencies forwarded to the Scanner (T12 Save). The
    /// composition root injects the shared instances so a card saved after
    /// recognition lands in the same repository this Holder reads. Both
    /// are optional: the Holder lists cards without them, and Previews /
    /// tests that never enter the Scanner may omit them.
    let cardRepository: (any BusinessCardRepository)?
    let imageStore: (any ImageAssetStore)?

    init(
        viewModel: CardHolderViewModel,
        cardRepository: (any BusinessCardRepository)? = nil,
        imageStore: (any ImageAssetStore)? = nil
    ) {
        self.viewModel = viewModel
        self.cardRepository = cardRepository
        self.imageStore = imageStore
    }

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
                        // T12: forward the store so cards saved this
                        // session render their real processed-image
                        // thumbnail (fixture-seeded / preview cards
                        // without stored assets stay text-only).
                        BusinessCardRow(card: card, imageStore: imageStore)
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
                // T14: forward the shared Repository so Existing-Card
                // Editing replaces the same-id entity in the store the
                // Holder lists. Production always injects it; Previews /
                // throwaway contexts fall back to an isolated repository
                // seeded with this card.
                if let card = viewModel.cards.first(where: { $0.id == id }) {
                    CardDetailView(viewModel: CardDetailViewModel(
                        card: card,
                        repository: cardRepository
                            ?? InMemoryBusinessCardRepository(initialCards: [card])
                    ))
                }
                // A missing id cannot occur via holder row taps; an empty
                // fallback is sufficient for the typed initializer.
            case .scan:
                // P02 Scanner. Forward the shared persistence dependencies
                // so the T12 save path (recognition → corrected draft →
                // final BusinessCard) writes into the same repository this
                // Holder lists, and stores the card's image assets.
                ScanEntryView(cardRepository: cardRepository, imageStore: imageStore)
            }
        }
        .onAppear {
            // Reload on every appearance so a card saved in the Scanner
            // (T12) is listed immediately when P06 完成 pops back here.
            // The repository defines no ordering; membership is what
            // matters. Initial load also runs via the App's `.task`.
            Task { await viewModel.loadCards() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Typed navigation entry to the Scanner shell (T02).
                // Reuses the same NavigationStack + AppRoute system as
                // card rows; no parallel Bool/sheet state.
                NavigationLink(value: AppRoute.scan) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("扫描")
                .accessibilityIdentifier("scan-entry")
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
