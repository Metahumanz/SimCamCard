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

    // MARK: - T15 Search projection (MockBusinessCards fixture)

    /// Loads a Holder ViewModel seeded with the deterministic populated
    /// fixture used by the UI tests.
    @MainActor
    private func makeLoadedFixtureViewModel(
        repository repo: InMemoryBusinessCardRepository = InMemoryBusinessCardRepository(
            initialCards: MockBusinessCards.all
        )
    ) async throws -> (CardHolderViewModel, InMemoryBusinessCardRepository) {
        let viewModel = CardHolderViewModel(repository: repo)
        await viewModel.loadCards()
        return (viewModel, repo)
    }

    @Test("T15 initial state: empty query, not searching, visibleCards equals cards")
    func t15InitialSearchStateIsInactive() async throws {
        let (viewModel, _) = try await makeLoadedFixtureViewModel()

        #expect(viewModel.searchQuery == "")
        #expect(!viewModel.isSearching)
        #expect(
            Set(viewModel.visibleCards.map(\.id))
                == Set(viewModel.cards.map(\.id))
        )
        #expect(viewModel.visibleCards.count == 3)
    }

    @Test("T15 name search returns matching cards by membership")
    func t15NameSearch() async throws {
        let (viewModel, _) = try await makeLoadedFixtureViewModel()

        viewModel.searchQuery = "张伟"
        #expect(viewModel.isSearching)
        // Fixture: card 001 and card 004 are both named 张伟.
        #expect(
            Set(viewModel.visibleCards.map(\.id))
                == [MockBusinessCards.card001ID, MockBusinessCards.card004ID]
        )
    }

    @Test("T15 company search returns matching cards")
    func t15CompanySearch() async throws {
        let (viewModel, _) = try await makeLoadedFixtureViewModel()

        viewModel.searchQuery = "智云"
        #expect(
            Set(viewModel.visibleCards.map(\.id))
                == [MockBusinessCards.card001ID, MockBusinessCards.card002ID]
        )
    }

    @Test("T15 job-title search hits the bilingual title")
    func t15JobTitleSearch() async throws {
        let (viewModel, _) = try await makeLoadedFixtureViewModel()

        viewModel.searchQuery = "Product Director"
        #expect(Set(viewModel.visibleCards.map(\.id)) == [MockBusinessCards.card001ID])
    }

    @Test("T15 digits-only phone search hits cards whose stored number is formatted")
    func t15PhoneSearch() async throws {
        let (viewModel, _) = try await makeLoadedFixtureViewModel()

        // Stored as "+86 138 0013 8000" on card 001 and card 004.
        viewModel.searchQuery = "13800138000"
        #expect(
            Set(viewModel.visibleCards.map(\.id))
                == [MockBusinessCards.card001ID, MockBusinessCards.card004ID]
        )
    }

    @Test("T15 email local-part search hits the owning card")
    func t15EmailSearch() async throws {
        let (viewModel, _) = try await makeLoadedFixtureViewModel()

        viewModel.searchQuery = "wei.zhang"
        #expect(Set(viewModel.visibleCards.map(\.id)) == [MockBusinessCards.card001ID])
    }

    @Test("T15 a query with zero hits yields an empty projection while searching")
    func t15NoResultSearch() async throws {
        let (viewModel, _) = try await makeLoadedFixtureViewModel()

        viewModel.searchQuery = "查无此名片-zzzz"
        #expect(viewModel.isSearching)
        #expect(viewModel.visibleCards.isEmpty)
    }

    @Test("T15 clearing the query restores the full snapshot")
    func t15ClearRestoresFullCards() async throws {
        let (viewModel, _) = try await makeLoadedFixtureViewModel()

        viewModel.searchQuery = "智云"
        #expect(viewModel.visibleCards.count == 2)
        viewModel.clearSearch()
        #expect(!viewModel.isSearching)
        #expect(viewModel.searchQuery == "")
        #expect(viewModel.visibleCards.count == 3)
        #expect(
            Set(viewModel.visibleCards.map(\.id))
                == Set(MockBusinessCards.all.map(\.id))
        )
    }

    @Test("T15 searching never mutates the snapshot or the repository")
    func t15SearchNeverMutatesSnapshotOrRepository() async throws {
        let (viewModel, repo) = try await makeLoadedFixtureViewModel()

        let snapshotIDs = Set(viewModel.cards.map(\.id))
        let snapshotValues = viewModel.cards

        for query in ["张伟", "智云", "Product Director", "13800138000",
                      "wei.zhang", "查无此名片-zzzz", "   "] {
            viewModel.searchQuery = query
            _ = viewModel.visibleCards
        }
        viewModel.clearSearch()

        // The owner snapshot is untouched (identity AND values), and the
        // repository contents are unchanged.
        #expect(Set(viewModel.cards.map(\.id)) == snapshotIDs)
        #expect(viewModel.cards == snapshotValues)
        let stored = await repo.allCards()
        #expect(Set(stored.map(\.id)) == snapshotIDs)
        #expect(stored.count == 3)
    }

    @Test("T15 freshly loaded repository field values participate in search naturally")
    func t15RepositoryEditsParticipateAfterReload() async throws {
        // A card saved/edited in the repository and reloaded must be
        // searchable by its new value — no ViewModel-side cache of
        // searchable text exists.
        let repo = InMemoryBusinessCardRepository(initialCards: [])
        let (viewModel, _) = try await makeLoadedFixtureViewModel(repository: repo)
        #expect(viewModel.visibleCards.isEmpty)

        let card = BusinessCard(
            originalImageReference: "o",
            processedImageReference: "p",
            name: "新同事",
            company: "新公司"
        )
        await repo.save(card)
        await viewModel.loadCards()

        viewModel.searchQuery = "新同事"
        #expect(Set(viewModel.visibleCards.map(\.id)) == [card.id])
        viewModel.searchQuery = "新公司"
        #expect(Set(viewModel.visibleCards.map(\.id)) == [card.id])
    }
    #endif
}
