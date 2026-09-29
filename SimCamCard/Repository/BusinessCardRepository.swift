//
//  BusinessCardRepository.swift
//  SimCamCard
//
//  Data-access abstraction for BusinessCard storage.
//  ViewModels depend on this protocol, never on a concrete storage
//  implementation (InMemory for Week 2; real persistence later).
//
//  Spec source: spec/data-model.md §BusinessCard (id, createdAt,
//  updatedAt), §Persistence rule; spec/reference-tests.md T12 Save,
//  T17 Delete, T18 Persistence (T18 not implemented in Week 2).
//
//  Swift 6 concurrency:
//   - The protocol is `nonisolated` because the App target defaults to
//     SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor. Storage must be usable
//     from a generic actor (e.g. InMemoryBusinessCardRepository) and from
//     non-MainActor contexts.
//   - All operations are `async` so conforming types may be actor-isolated
//     or backed by real persistence without changing the call sites.
//

import Foundation

nonisolated protocol BusinessCardRepository: Sendable {

    /// All cards currently held by the repository.
    ///
    /// Ordering is implementation-defined; the frozen spec defines no
    /// product-level sort for the Card Holder list. Callers must not rely
    /// on name/date ordering from this contract.
    func allCards() async -> [BusinessCard]

    /// Returns the card with the given stable id, or nil if no such card
    /// is held.
    func card(id: UUID) async -> BusinessCard?

    /// Inserts a new card, or replaces the existing card with the same id.
    ///
    /// - A repeated id updates the single stored entity; it never produces
    ///   a duplicate record.
    /// - The repository stores the entity exactly as given. It does not
    ///   mutate `updatedAt` or any other field (timestamp maintenance is
    ///   a business-layer responsibility, not storage).
    func save(_ card: BusinessCard) async

    /// Removes the card with the given id.
    ///
    /// Safe no-op when no card with that id exists; the frozen spec
    /// defines no error for deleting an absent card (T17 only requires
    /// that the card disappears afterward).
    func delete(id: UUID) async
}
