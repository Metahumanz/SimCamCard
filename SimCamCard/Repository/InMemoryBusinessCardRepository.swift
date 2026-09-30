//
//  InMemoryBusinessCardRepository.swift
//  SimCamCard
//
//  Week 2 in-memory implementation of BusinessCardRepository.
//
//  Data exists only for the process lifetime and is lost when the app
//  terminates. This is expected for the Week 2 skeleton; real persistence
//  (T18, spec/data-model.md §Persistence rule) is deferred and must be
//  introduced behind the same BusinessCardRepository abstraction.
//
//  Swift 6 concurrency:
//   - Implemented as an `actor`: the mutable `cards` storage is serialized
//     through actor isolation, and the type is automatically Sendable.
//   - No mutable class, no locks, no @unchecked Sendable.
//   - Actor-isolated synchronous methods witness the protocol's
//     nonisolated async requirements; cross-actor callers await.
//

import Foundation

actor InMemoryBusinessCardRepository: BusinessCardRepository {

    /// Insertion-ordered storage.
    ///
    /// An array (rather than a dictionary plus an ordering structure) is
    /// sufficient for Week 2 data volumes. Insertion order and update
    /// positioning are CURRENT IN-MEMORY IMPLEMENTATION DETAILS ONLY; they
    /// are NOT part of the BusinessCardRepository contract. The frozen spec
    /// defines no order for the Card Holder list, and callers/tests must not
    /// depend on array position. A future persistence implementation may
    /// return cards in any order.
    private var cards: [BusinessCard]

    /// Creates a repository.
    ///
    /// - Parameter initialCards: optional deterministic fixtures injected
    ///   at construction (used by DEBUG / UI-test seeding; empty for normal
    ///   Week 2 runtime). Seed cards are folded with the same insert-or-
    ///   update semantics as `save(_:)`: a repeated id replaces the earlier
    ///   card's value and never produces duplicates. (Relative array
    ///   position of collapsed seeds is an implementation detail, not a
    ///   contract.)
    init(initialCards: [BusinessCard] = []) {
        var seeded: [BusinessCard] = []
        for card in initialCards {
            if let index = seeded.firstIndex(where: { $0.id == card.id }) {
                seeded[index] = card
            } else {
                seeded.append(card)
            }
        }
        self.cards = seeded
    }

    // MARK: - BusinessCardRepository

    func allCards() -> [BusinessCard] {
        cards
    }

    func card(id: UUID) -> BusinessCard? {
        cards.first { $0.id == id }
    }

    func save(_ card: BusinessCard) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            // Update in place: same id replaces the single stored entity.
            // (Position retention is an in-memory implementation detail.)
            cards[index] = card
        } else {
            cards.append(card)
        }
    }

    func delete(id: UUID) {
        // Absent id: removeAll matches nothing — a safe no-op.
        cards.removeAll { $0.id == id }
    }
}
