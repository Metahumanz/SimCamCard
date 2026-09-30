//
//  InMemoryBusinessCardRepositoryTests.swift
//  SimCamCardTests
//
//  Unit tests for the Week 2 in-memory repository and the
//  BusinessCardRepository contract it satisfies.
//
//  Spec sources:
//   - spec/reference-tests.md T12 Save, T17 Delete — repository-level
//     PREREQUISITES/SUPPORT ONLY. The full T12 ("immediately appears") and
//     T17 ("disappears afterward") UI behaviors require ViewModel + View and
//     are verified in later increments; Increment 2 must not claim them.
//   - spec/state-inventory.md S01 (empty / populated)
//   - spec/data-model.md §BusinessCard (stable id)
//  T18 Persistence is intentionally NOT covered: Week 2 storage is
//  process-local and expected to be lost on termination.
//
//  Ordering note:
//  The frozen spec defines no ordering for allCards(). These tests assert
//  SET MEMBERSHIP and id-based lookup only — never array position or
//  insertion order. Insertion order is an in-memory implementation detail,
//  not part of the BusinessCardRepository contract.
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("InMemoryBusinessCardRepository")
struct InMemoryBusinessCardRepositoryTests {

    // MARK: - Fixtures

    /// Builds a minimal valid card. Image references are required by the
    /// Domain Model; deterministic tokens are supplied here.
    private func makeCard(
        id: UUID = UUID(),
        name: String? = nil,
        original: String = "test-original",
        processed: String = "test-processed",
        createdAt: Date = Date(timeIntervalSince1970: 1_000_000_000),
        updatedAt: Date = Date(timeIntervalSince1970: 1_000_000_000)
    ) -> BusinessCard {
        BusinessCard(
            id: id,
            originalImageReference: original,
            processedImageReference: processed,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - Empty repository

    @Test("a fresh repository is empty")
    func freshRepositoryIsEmpty() async throws {
        let repo = InMemoryBusinessCardRepository()
        let cards = await repo.allCards()
        #expect(cards.isEmpty)
        #expect(await repo.card(id: UUID()) == nil)
    }

    // MARK: - Initializer injection

    @Test("initializer injection returns the seed cards (membership, no order assumed)")
    func initializerInjectionReturnsSeedCards() async throws {
        let a = makeCard(name: "A")
        let b = makeCard(name: "B")
        let c = makeCard(name: "C")
        let repo = InMemoryBusinessCardRepository(initialCards: [a, b, c])

        let cards = await repo.allCards()
        #expect(cards.count == 3)
        // Membership only: the contract does not define return order.
        #expect(Set(cards.map(\.id)) == [a.id, b.id, c.id])
        #expect(await repo.card(id: a.id)?.name == "A")
        #expect(await repo.card(id: b.id)?.name == "B")
        #expect(await repo.card(id: c.id)?.name == "C")
    }

    // Note: no test for duplicate ids inside `initialCards`. The frozen spec
    // does not define first-wins vs last-wins for repeated seed ids, so that
    // behavior is not a contract and is not asserted. id uniqueness after
    // `save` is covered by `saveExistingIdReplacesWithoutDuplicate`.

    // MARK: - save(_:)

    @Test("saving a new card inserts it and makes it retrievable by id")
    func saveNewCardInserts() async throws {
        let repo = InMemoryBusinessCardRepository()
        let card = makeCard(name: "张伟")
        await repo.save(card)

        let cards = await repo.allCards()
        #expect(cards.count == 1)
        #expect(Set(cards.map(\.id)) == [card.id])
        #expect(await repo.card(id: card.id) == card)
    }

    @Test("saving an existing id replaces it without duplicating (no position contract)")
    func saveExistingIdReplacesWithoutDuplicate() async throws {
        let repo = InMemoryBusinessCardRepository()
        let first = makeCard(name: "first")
        let target = makeCard(name: "target")
        let third = makeCard(name: "third")
        await repo.save(first)
        await repo.save(target)
        await repo.save(third)

        let updated = BusinessCard(
            id: target.id,
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            name: "target-updated",
            jobTitle: "产品总监"
        )
        await repo.save(updated)

        let cards = await repo.allCards()
        // Contract: count unchanged, ids unique, id lookup returns the new entity.
        // No element position or return order is asserted (ordering is not a
        // Repository contract).
        #expect(cards.count == 3)
        let ids = cards.map(\.id)
        #expect(Set(ids) == Set([first.id, target.id, third.id]))
        #expect(ids.count == 3)
        #expect(Set(ids).count == ids.count) // ids unique, no duplicate record
        #expect(await repo.card(id: target.id) == updated)
    }

    @Test("save stores the entity verbatim and never mutates updatedAt")
    func saveStoresEntityVerbatim() async throws {
        let repo = InMemoryBusinessCardRepository()
        let created = Date(timeIntervalSince1970: 1_000_000_000)
        let updated = Date(timeIntervalSince1970: 2_000_000_000)
        let card = makeCard(name: "原样", createdAt: created, updatedAt: updated)
        await repo.save(card)

        let stored = try #require(await repo.card(id: card.id))
        #expect(stored == card)
        #expect(stored.createdAt == created)
        #expect(stored.updatedAt == updated)
        #expect(stored.name == "原样")
    }

    // MARK: - delete(id:)

    @Test("deleting an existing card removes it (membership, no order assumed)")
    func deleteExistingCardRemoves() async throws {
        let repo = InMemoryBusinessCardRepository()
        let a = makeCard(name: "A")
        let b = makeCard(name: "B")
        await repo.save(a)
        await repo.save(b)

        await repo.delete(id: a.id)

        let cards = await repo.allCards()
        #expect(cards.count == 1)
        #expect(Set(cards.map(\.id)) == [b.id])
        #expect(await repo.card(id: a.id) == nil)
        #expect(await repo.card(id: b.id)?.name == "B")
    }

    @Test("deleting an absent id is a safe no-op")
    func deleteAbsentIdIsNoOp() async throws {
        let repo = InMemoryBusinessCardRepository()
        let a = makeCard(name: "A")
        await repo.save(a)

        await repo.delete(id: UUID()) // unknown id, must not throw

        let cards = await repo.allCards()
        #expect(cards.count == 1)
        #expect(Set(cards.map(\.id)) == [a.id])
    }

    // MARK: - Interleaved sequence

    @Test("interleaved saves and deletes converge to the expected member set (no order assumed)")
    func interleavedSavesAndDeletes() async throws {
        let repo = InMemoryBusinessCardRepository()
        let a = makeCard(name: "A")
        let b = makeCard(name: "B")
        let c = makeCard(name: "C")

        await repo.save(a)
        await repo.save(b)
        await repo.delete(id: a.id)
        await repo.save(c)
        await repo.delete(id: UUID()) // no-op
        await repo.delete(id: b.id)

        let cards = await repo.allCards()
        // Final member set and entity content only; order not part of contract.
        #expect(cards.count == 1)
        #expect(Set(cards.map(\.id)) == [c.id])
        #expect(await repo.card(id: c.id)?.name == "C")
        #expect(await repo.card(id: a.id) == nil)
        #expect(await repo.card(id: b.id) == nil)
    }

    // MARK: - Concurrency

    @Test("concurrent saves of distinct ids all persist (no execution order assumed)")
    func concurrentSavesAllPersist() async throws {
        let repo = InMemoryBusinessCardRepository()
        let a = makeCard(name: "A")
        let b = makeCard(name: "B")

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await repo.save(a) }
            group.addTask { await repo.save(b) }
        }

        let cards = await repo.allCards()
        // All writes must be present; task completion order is not asserted.
        #expect(cards.count == 2)
        #expect(Set(cards.map(\.id)) == [a.id, b.id])
    }
}
