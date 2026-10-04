//
//  CardHolderViewModel.swift
//  SimCamCard
//
//  UI-facing state owner for the Card Holder page (P01).
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder
//   - spec/state-inventory.md S01 (empty / populated)
//   - spec/reference-tests.md T01 Empty Card Holder
//
//  Architecture (one state, one owner):
//   - Repository = data source abstraction (any BusinessCardRepository)
//   - ViewModel  = UI-facing state + orchestration
//   - View       = rendering + user intent
//
//  The ViewModel is the SOLE owner of `cards`. The View reads
//  `viewModel.cards` directly and does NOT maintain its own
//  `[BusinessCard]` copy.
//
//  T15 Search (Week 4 Increment 6):
//   - `searchQuery` is UI state owned here as well. Search is a pure
//     PRESENTATION filter over the repository snapshot: it never mutates
//     `cards`, the repository, or any BusinessCard.
//   - `visibleCards` is the derived projection: empty query → the full
//     `cards` snapshot; active query → cards filtered by the
//     deterministic BusinessCardSearchMatcher. Both the Holder list and
//     the P08 Search Results page read this single projection; the View
//     never holds a second filtered array.
//   - A later T16 group pass can compose `snapshot → group filter →
//     search filter` without rewriting the matcher.
//
//  Swift 6 concurrency:
//   - @MainActor: all UI state mutations happen on the main actor.
//   - @Observable: Swift Observation framework (not Combine). The View
//     tracks `cards` access in its body and re-renders on change.
//   - The repository is an `actor` with an async API, so `loadCards()`
//     awaits `repository.allCards()` across the actor boundary.
//

import Foundation
import Observation

@MainActor
@Observable
final class CardHolderViewModel {

    /// The current set of cards held by the Card Holder.
    ///
    /// `private(set)`: only the ViewModel mutates this (via `loadCards()`).
    /// The View reads this property directly — it does NOT hold its own
    /// `[BusinessCard]` copy. T15 search never mutates this snapshot.
    private(set) var cards: [BusinessCard] = []

    /// Live search text (P08 Search Results field binding). The View
    /// binds the TextField here; no second query copy exists in a View.
    var searchQuery: String = ""

    /// Data source abstraction. `let` — injected at construction and
    /// never replaced. The concrete repository type is not known to or
    /// stored by the View.
    private let repository: any BusinessCardRepository

    /// Stateless deterministic T15 predicate (name / company / jobTitle /
    /// phone-digits / email).
    private let searchMatcher = BusinessCardSearchMatcher()

    init(repository: any BusinessCardRepository) {
        self.repository = repository
    }

    /// Loads all cards from the repository into `cards`.
    ///
    /// Called on view appearance via `.task`. On an empty repository
    /// (normal Week 2 launch), `cards` remains `[]` — the S01 `empty`
    /// state. On a populated repository, `cards` reflects the stored
    /// set (membership only; ordering is implementation-defined per the
    /// BusinessCardRepository contract).
    func loadCards() async {
        cards = await repository.allCards()
    }

    // MARK: - T15 Search projection

    /// True while a non-empty query is active (S01 `searching`).
    /// Whitespace-only text is not an active search.
    var isSearching: Bool {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    /// The cards the UI should show right now:
    ///   - no active query → the full repository snapshot (`cards`);
    ///   - active query   → the snapshot filtered through the
    ///                      deterministic matcher (membership/order of
    ///                      the snapshot is preserved; search never
    ///                      re-sorts or mutates it).
    /// Derived state — never stored, never a second owner of card data.
    var visibleCards: [BusinessCard] {
        guard isSearching else { return cards }
        let query = searchQuery
        return cards.filter { searchMatcher.matches(card: $0, query: query) }
    }

    /// Clears the active query, restoring the full snapshot
    /// (× affordance / Back from the Search Results page).
    func clearSearch() {
        searchQuery = ""
    }
}
