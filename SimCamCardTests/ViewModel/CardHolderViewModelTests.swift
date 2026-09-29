//
//  CardHolderViewModelTests.swift
//  SimCamCardTests
//
//  Unit tests for CardHolderViewModel (Swift Testing).
//
//  Spec sources:
//   - spec/state-inventory.md S01 (empty / populated)
//   - spec/reference-tests.md T01 Empty Card Holder
//   - spec/page-inventory.md P01 Card Holder
//
//  Architecture verified:
//   - ViewModel is the SOLE owner of `cards` (private(set)).
//   - View does NOT hold its own [BusinessCard] — tested by confirming
//     `cards` is only mutated through `loadCards()`.
//   - Repository is injected; ViewModel depends on the protocol, not the
//     concrete InMemoryBusinessCardRepository.
//
//  These tests use InMemoryBusinessCardRepository with seeded cards to
//  verify load logic. This is TEST-ONLY fixture injection — the normal
//  app runtime launches with an empty repository (no mock data).
//

import Testing
import Foundation
@testable import SimCamCard

@MainActor
@Suite("CardHolderViewModel")
struct CardHolderViewModelTests {

    // MARK: - Fixtures

    /// Builds a minimal valid card for test seeding.
    private func makeCard(
        id: UUID = UUID(),
        name: String? = nil
    ) -> BusinessCard {
        BusinessCard(
            id: id,
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            name: name
        )
    }

    // MARK: - Fresh ViewModel state

    @Test("a fresh ViewModel starts with empty cards before loadCards is called")
    func freshViewModelHasEmptyCards() async throws {
        let repo = InMemoryBusinessCardRepository()
        let viewModel = CardHolderViewModel(repository: repo)

        #expect(viewModel.cards.isEmpty)
        #expect(viewModel.cards.count == 0)
    }

    // MARK: - loadCards with empty repository

    @Test("loadCards on an empty repository keeps cards empty")
    func loadCardsWithEmptyRepositoryProducesEmptyCards() async throws {
        let repo = InMemoryBusinessCardRepository()
        let viewModel = CardHolderViewModel(repository: repo)

        await viewModel.loadCards()

        #expect(viewModel.cards.isEmpty)
        #expect(viewModel.cards.count == 0)
    }

    // MARK: - loadCards with populated repository

    @Test("loadCards on a populated repository reflects the repository's cards")
    func loadCardsWithPopulatedRepositoryReflectsRepositoryCards() async throws {
        let cardA = makeCard(name: "张伟")
        let cardB = makeCard(name: "李娜")
        let repo = InMemoryBusinessCardRepository(initialCards: [cardA, cardB])
        let viewModel = CardHolderViewModel(repository: repo)

        await viewModel.loadCards()

        // Membership only — ordering is NOT a repository contract.
        #expect(viewModel.cards.count == 2)
        #expect(Set(viewModel.cards.map(\.id)) == [cardA.id, cardB.id])
    }

    // MARK: - loadCards idempotency

    @Test("loadCards is idempotent — calling twice produces the same result")
    func loadCardsIsIdempotent() async throws {
        let cardA = makeCard(name: "张伟")
        let cardB = makeCard(name: "李娜")
        let repo = InMemoryBusinessCardRepository(initialCards: [cardA, cardB])
        let viewModel = CardHolderViewModel(repository: repo)

        await viewModel.loadCards()
        let firstLoad = Set(viewModel.cards.map(\.id))

        await viewModel.loadCards()
        let secondLoad = Set(viewModel.cards.map(\.id))

        #expect(firstLoad == secondLoad)
        #expect(viewModel.cards.count == 2)
    }

    // MARK: - loadCards reflects repository mutations

    @Test("loadCards after a repository save reflects the new card")
    func loadCardsAfterRepositorySaveReflectsNewCard() async throws {
        let repo = InMemoryBusinessCardRepository()
        let viewModel = CardHolderViewModel(repository: repo)

        await viewModel.loadCards()
        #expect(viewModel.cards.isEmpty)

        // Save a card to the repository, then reload.
        let card = makeCard(name: "新增名片")
        await repo.save(card)
        await viewModel.loadCards()

        #expect(viewModel.cards.count == 1)
        #expect(Set(viewModel.cards.map(\.id)) == [card.id])
    }

    // MARK: - loadCards after a repository delete

    @Test("loadCards after a repository delete reflects the removal")
    func loadCardsAfterRepositoryDeleteReflectsRemoval() async throws {
        let cardA = makeCard(name: "张伟")
        let cardB = makeCard(name: "李娜")
        let repo = InMemoryBusinessCardRepository(initialCards: [cardA, cardB])
        let viewModel = CardHolderViewModel(repository: repo)

        await viewModel.loadCards()
        #expect(viewModel.cards.count == 2)

        await repo.delete(id: cardA.id)
        await viewModel.loadCards()

        #expect(viewModel.cards.count == 1)
        #expect(Set(viewModel.cards.map(\.id)) == [cardB.id])
    }

    // MARK: - loadCards with the deterministic Mock fixture set

    #if DEBUG
    @Test("loadCards with the MockBusinessCards fixture returns the expected membership")
    func loadCardsWithMockBusinessCardsFixtureReturnsExpectedMembership() async throws {
        // DEBUG-only fixture path. MockBusinessCards is compiled out under
        // #if DEBUG, so this test is wrapped to avoid a compile error in
        // Release builds of the test target.
        let seeded = MockBusinessCards.all
        let repo = InMemoryBusinessCardRepository(initialCards: seeded)
        let viewModel = CardHolderViewModel(repository: repo)

        await viewModel.loadCards()

        // Membership only — Repository contract defines no order, so
        // assertion is set-based, not positional.
        #expect(viewModel.cards.count == MockBusinessCards.all.count)
        #expect(
            Set(viewModel.cards.map(\.id))
                == Set(MockBusinessCards.all.map(\.id))
        )
    }
    #endif
}
