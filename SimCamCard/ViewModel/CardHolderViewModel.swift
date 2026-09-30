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
    /// `[BusinessCard]` copy.
    private(set) var cards: [BusinessCard] = []

    /// Data source abstraction. `let` — injected at construction and
    /// never replaced. The concrete repository type is not known to or
    /// stored by the View.
    private let repository: any BusinessCardRepository

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
}
