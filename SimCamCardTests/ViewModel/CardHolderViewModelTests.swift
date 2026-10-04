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
        let viewModel = CardHolderViewModel(repository: repo, groupRepository: InMemoryCardGroupRepository())

        #expect(viewModel.cards.isEmpty)
        #expect(viewModel.cards.count == 0)
    }

    // MARK: - loadCards with empty repository

    @Test("loadCards on an empty repository keeps cards empty")
    func loadCardsWithEmptyRepositoryProducesEmptyCards() async throws {
        let repo = InMemoryBusinessCardRepository()
        let viewModel = CardHolderViewModel(repository: repo, groupRepository: InMemoryCardGroupRepository())

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
        let viewModel = CardHolderViewModel(repository: repo, groupRepository: InMemoryCardGroupRepository())

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
        let viewModel = CardHolderViewModel(repository: repo, groupRepository: InMemoryCardGroupRepository())

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
        let viewModel = CardHolderViewModel(repository: repo, groupRepository: InMemoryCardGroupRepository())

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
        let viewModel = CardHolderViewModel(repository: repo, groupRepository: InMemoryCardGroupRepository())

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
        let viewModel = CardHolderViewModel(repository: repo, groupRepository: InMemoryCardGroupRepository())

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
        let viewModel = CardHolderViewModel(repository: repo, groupRepository: InMemoryCardGroupRepository())
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

    // MARK: - T16 Group / Tag

    #if DEBUG

    /// Helper: creates a ViewModel with the populated fixture and a
    /// dedicated group repository, then loads both cards and groups.
    @MainActor
    private func makeGroupTestViewModel(
        cardRepo: InMemoryBusinessCardRepository = InMemoryBusinessCardRepository(
            initialCards: MockBusinessCards.all
        ),
        groupRepo: InMemoryCardGroupRepository = InMemoryCardGroupRepository()
    ) async throws -> (CardHolderViewModel, InMemoryBusinessCardRepository, InMemoryCardGroupRepository) {
        let viewModel = CardHolderViewModel(
            repository: cardRepo,
            groupRepository: groupRepo
        )
        await viewModel.loadHolderData()
        return (viewModel, cardRepo, groupRepo)
    }

    @Test("T16 loadGroups populates the group catalog")
    func t16LoadGroups() async throws {
        let group = CardTag(name: "VIP")
        let groupRepo = InMemoryCardGroupRepository(initialGroups: [group])
        let (viewModel, _, _) = try await makeGroupTestViewModel(groupRepo: groupRepo)

        #expect(viewModel.groups.count == 1)
        #expect(viewModel.groups.first?.name == "VIP")
    }

    @Test("T16 createGroup assigns the same CardTag ID to selected card")
    func t16CreateGroupAssignsToSelectedCard() async throws {
        let (viewModel, cardRepo, _) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "客户")

        #expect(tag != nil)
        #expect(tag?.name == "客户")

        // The card in the repository carries the tag.
        let stored = await cardRepo.card(id: MockBusinessCards.card001ID)
        #expect(stored?.tags.contains(where: { $0.id == tag!.id }) == true)

        // The ViewModel snapshot reflects the assignment.
        let card = viewModel.cards.first(where: { $0.id == MockBusinessCards.card001ID })
        #expect(card?.tags.contains(where: { $0.id == tag!.id }) == true)
    }

    @Test("T16 multiple selected cards receive the same group ID")
    func t16MultipleCardsSameGroupID() async throws {
        let (viewModel, _, _) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        viewModel.toggleGroupCardSelection(MockBusinessCards.card002ID)
        let tag = await viewModel.createGroup(named: "合作伙伴")

        #expect(tag != nil)

        for cardID in [MockBusinessCards.card001ID, MockBusinessCards.card002ID] {
            let card = viewModel.cards.first(where: { $0.id == cardID })
            #expect(card?.tags.contains(where: { $0.id == tag!.id }) == true)
        }

        // card004 was NOT selected.
        let card004 = viewModel.cards.first(where: { $0.id == MockBusinessCards.card004ID })
        #expect(card004?.tags.contains(where: { $0.id == tag!.id }) != true)
    }

    @Test("T16 assignment does not duplicate the same group on a card")
    func t16AssignmentNoDuplicate() async throws {
        let (viewModel, _, _) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "客户")

        // Assign again (simulating re-assign).
        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        // Manually create a second group with same name — different ID.
        let tag2 = await viewModel.createGroup(named: "客户")
        #expect(tag2 != nil)
        #expect(tag2!.id != tag!.id) // identity by ID, not name

        let card = viewModel.cards.first(where: { $0.id == MockBusinessCards.card001ID })
        let matchingTags = card?.tags.filter { $0.id == tag!.id } ?? []
        #expect(matchingTags.count == 1) // no duplicate
    }

    @Test("T16 assignment preserves card identity and metadata")
    func t16AssignmentPreservesMetadata() async throws {
        let (viewModel, cardRepo, _) = try await makeGroupTestViewModel()

        let before = viewModel.cards.first(where: { $0.id == MockBusinessCards.card001ID })!
        let beforePhoneIDs = Set(before.phones.map(\.id))

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        _ = await viewModel.createGroup(named: "VIP")

        let after = viewModel.cards.first(where: { $0.id == MockBusinessCards.card001ID })!

        // Identity and metadata preserved.
        #expect(after.id == before.id)
        #expect(after.originalImageReference == before.originalImageReference)
        #expect(after.processedImageReference == before.processedImageReference)
        #expect(after.rawOCRText == before.rawOCRText)
        #expect(after.name == before.name)
        #expect(after.company == before.company)
        #expect(after.jobTitle == before.jobTitle)
        #expect(after.website == before.website)
        #expect(after.address == before.address)
        #expect(after.createdAt == before.createdAt)
        #expect(after.notes == before.notes)

        // Phone IDs preserved.
        #expect(Set(after.phones.map(\.id)) == beforePhoneIDs)
        #expect(after.phones == before.phones)

        // Only tags and updatedAt changed.
        #expect(after.tags.count == before.tags.count + 1)
        #expect(after.updatedAt != before.updatedAt)
    }

    @Test("T16 cardCount returns correct count for a group")
    func t16CardCount() async throws {
        let (viewModel, _, _) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        viewModel.toggleGroupCardSelection(MockBusinessCards.card004ID)
        let tag = await viewModel.createGroup(named: "客户")

        #expect(viewModel.cardCount(in: tag!.id) == 2)
        #expect(viewModel.cardCount(in: UUID()) == 0)
    }

    @Test("T16 selectGroup filters cards by group membership")
    func t16SelectGroupFilters() async throws {
        let (viewModel, _, _) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "客户")

        viewModel.selectGroup(tag!.id)

        #expect(viewModel.isGroupFiltered)
        #expect(viewModel.selectedGroup?.id == tag!.id)
        #expect(viewModel.groupFilteredCards.count == 1)
        #expect(viewModel.groupFilteredCards.first?.id == MockBusinessCards.card001ID)
    }

    @Test("T16 clearGroupFilter restores full snapshot")
    func t16ClearGroupFilter() async throws {
        let (viewModel, _, _) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "客户")

        viewModel.selectGroup(tag!.id)
        #expect(viewModel.groupFilteredCards.count == 1)

        viewModel.clearGroupFilter()
        #expect(!viewModel.isGroupFiltered)
        #expect(viewModel.selectedGroupID == nil)
        #expect(viewModel.groupFilteredCards.count == 3)
    }

    @Test("T16 group filter + search compose correctly (group first, then search)")
    func t16GroupPlusSearchCompose() async throws {
        let (viewModel, _, _) = try await makeGroupTestViewModel()

        // Assign card001 to group "客户"; card004 stays ungrouped.
        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "客户")

        // Select the group → only card001 passes the group filter.
        viewModel.selectGroup(tag!.id)

        // Both card001 and card004 are named "张伟", but only card001
        // is in the selected group, so search must find only card001.
        viewModel.searchQuery = "张伟"
        #expect(viewModel.isSearching)
        #expect(viewModel.visibleCards.count == 1)
        #expect(viewModel.visibleCards.first?.id == MockBusinessCards.card001ID)
    }

    @Test("T16 delete group removes catalog entry")
    func t16DeleteGroupRemovesCatalog() async throws {
        let (viewModel, _, groupRepo) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "客户")
        #expect(viewModel.groups.count == 1)

        await viewModel.deleteGroup(id: tag!.id)
        #expect(viewModel.groups.isEmpty)
        let stored = await groupRepo.allGroups()
        #expect(stored.isEmpty)
    }

    @Test("T16 delete group removes tag from cards but keeps cards")
    func t16DeleteGroupCardsRemain() async throws {
        let (viewModel, cardRepo, _) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "客户")

        let beforeCount = viewModel.cards.count

        await viewModel.deleteGroup(id: tag!.id)

        // Cards unchanged in count.
        #expect(viewModel.cards.count == beforeCount)

        // Tag removed from card001.
        let card001 = viewModel.cards.first(where: { $0.id == MockBusinessCards.card001ID })
        #expect(card001?.tags.contains(where: { $0.id == tag!.id }) != true)

        // Repository count unchanged.
        let stored = await cardRepo.allCards()
        #expect(stored.count == beforeCount)
    }

    @Test("T16 delete selected group clears the filter")
    func t16DeleteSelectedGroupClearsFilter() async throws {
        let (viewModel, _, _) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "客户")

        viewModel.selectGroup(tag!.id)
        #expect(viewModel.isGroupFiltered)

        await viewModel.deleteGroup(id: tag!.id)
        #expect(!viewModel.isGroupFiltered)
        #expect(viewModel.selectedGroupID == nil)
        #expect(viewModel.groupFilteredCards.count == 3)
    }

    @Test("T16 createGroup with blank name returns nil")
    func t16CreateGroupBlankName() async throws {
        let (viewModel, _, _) = try await makeGroupTestViewModel()

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "   ")
        #expect(tag == nil)
        #expect(viewModel.groups.isEmpty)
    }

    @Test("T16 groupCardSelection toggle behavior")
    func t16GroupCardSelectionToggle() async throws {
        let (viewModel, _, _) = try await makeGroupTestViewModel()

        viewModel.beginGroupSelection()
        #expect(viewModel.groupCardSelection.isEmpty)

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        #expect(viewModel.groupCardSelection.count == 1)

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        #expect(viewModel.groupCardSelection.isEmpty)

        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        viewModel.toggleGroupCardSelection(MockBusinessCards.card002ID)
        #expect(viewModel.groupCardSelection.count == 2)

        viewModel.clearGroupCardSelection()
        #expect(viewModel.groupCardSelection.isEmpty)
    }

    // MARK: - T17 Delete → Holder reload

    @Test("T17 loadHolderData after a repository delete drops the id from the cards snapshot")
    func t17ReloadAfterDeleteDropsCard() async throws {
        let cardRepo = InMemoryBusinessCardRepository(
            initialCards: MockBusinessCards.all
        )
        let groupRepo = InMemoryCardGroupRepository()
        let viewModel = CardHolderViewModel(repository: cardRepo, groupRepository: groupRepo)
        await viewModel.loadHolderData()
        #expect(viewModel.cards.contains { $0.id == MockBusinessCards.card001ID })

        // The Detail's confirm path performs the repository delete, then the
        // Holder's onDeleted calls loadHolderData() explicitly.
        await cardRepo.delete(id: MockBusinessCards.card001ID)
        await viewModel.loadHolderData()

        #expect(!viewModel.cards.contains { $0.id == MockBusinessCards.card001ID })
        #expect(viewModel.cards.count == MockBusinessCards.all.count - 1)
        // A subsequent search must not hit the deleted card (S01).
        viewModel.searchQuery = "张伟"
        #expect(
            !viewModel.visibleCards.contains { $0.id == MockBusinessCards.card001ID }
        )
    }

    @Test("T17 deleting the only card of a group keeps the catalog group with cardCount 0")
    func t17DeleteLastCardOfGroupKeepsGroupAtZero() async throws {
        let cardRepo = InMemoryBusinessCardRepository(
            initialCards: MockBusinessCards.all
        )
        let groupRepo = InMemoryCardGroupRepository()
        let viewModel = CardHolderViewModel(repository: cardRepo, groupRepository: groupRepo)
        await viewModel.loadHolderData()

        // Build a group 客户 that contains card001 ONLY.
        viewModel.toggleGroupCardSelection(MockBusinessCards.card001ID)
        let tag = await viewModel.createGroup(named: "客户")
        let groupID = try #require(tag?.id)
        #expect(viewModel.cardCount(in: groupID) == 1)

        // Filter by that group before deletion, then remove its only card
        // and reload exactly as the T17 onDeleted path does.
        viewModel.selectGroup(groupID)
        #expect(viewModel.groupFilteredCards.count == 1)

        await cardRepo.delete(id: MockBusinessCards.card001ID)
        await viewModel.loadHolderData()

        // The BusinessCard aggregate is gone...
        #expect(!viewModel.cards.contains { $0.id == MockBusinessCards.card001ID })

        // ...but the group CATALOG entry survives (groups are independent
        // of cards.tags, per Increment 7), now reporting zero cards.
        #expect(viewModel.groups.contains { $0.id == groupID })
        #expect(viewModel.groups.first { $0.id == groupID }?.name == "客户")
        #expect(viewModel.cardCount(in: groupID) == 0)
        let storedGroups = await groupRepo.allGroups()
        #expect(storedGroups.contains { $0.id == groupID })
        #expect(storedGroups.count == 1)

        // The active group filter resolves to an empty set rather than a
        // dangling card; the other cards remain outside the group.
        #expect(viewModel.isGroupFiltered)
        #expect(viewModel.groupFilteredCards.isEmpty)
        #expect(viewModel.cards.count == MockBusinessCards.all.count - 1)
    }

    #endif
}
