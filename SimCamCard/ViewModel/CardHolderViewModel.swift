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

    /// The current set of user-defined groups from the group catalog.
    /// `private(set)` — only the ViewModel mutates this (via `loadGroups()`).
    private(set) var groups: [CardTag] = []

    /// The group currently selected for filtering (S01 `groupFiltered`).
    /// nil means no group filter is active.
    var selectedGroupID: UUID?

    /// Live search text (P08 Search Results field binding). The View
    /// binds the TextField here; no second query copy exists in a View.
    var searchQuery: String = ""

    // MARK: - Transient group-creation state

    /// Card IDs selected during the "add to group" workflow.
    var groupCardSelection: Set<UUID> = []

    /// Name typed into the group-creation dialog.
    var pendingGroupName: String = ""

    /// Data source abstraction. `let` — injected at construction and
    /// never replaced. The concrete repository type is not known to or
    /// stored by the View.
    private let repository: any BusinessCardRepository

    /// Group catalog abstraction. `let` — injected at construction and
    /// never replaced.
    private let groupRepository: any CardGroupRepository

    /// Stateless deterministic T15 predicate (name / company / jobTitle /
    /// phone-digits / email).
    private let searchMatcher = BusinessCardSearchMatcher()

    init(
        repository: any BusinessCardRepository,
        groupRepository: any CardGroupRepository
    ) {
        self.repository = repository
        self.groupRepository = groupRepository
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

    /// Loads all user-defined groups from the group catalog.
    func loadGroups() async {
        groups = await groupRepository.allGroups()
    }

    /// Loads both cards and groups (production composition root entry
    /// point). Existing unit tests that only need cards can continue to
    /// call `loadCards()` alone.
    func loadHolderData() async {
        await loadCards()
        await loadGroups()
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
        let base = groupFilteredCards

        guard isSearching else {
            return base
        }

        return base.filter {
            searchMatcher.matches(
                card: $0,
                query: searchQuery
            )
        }
    }

    /// Clears the active query, restoring the full snapshot
    /// (× affordance / Back from the Search Results page).
    func clearSearch() {
        searchQuery = ""
    }

    // MARK: - T16 Group filter projection

    /// Cards filtered by the currently selected group.
    /// When no group is selected this returns the full `cards` snapshot.
    var groupFilteredCards: [BusinessCard] {
        guard let selectedGroupID else {
            return cards
        }

        return cards.filter { card in
            card.tags.contains { $0.id == selectedGroupID }
        }
    }

    /// True while a group filter is active (S01 `groupFiltered`).
    var isGroupFiltered: Bool {
        selectedGroupID != nil
    }

    /// The CardTag for the currently selected group, if any.
    var selectedGroup: CardTag? {
        guard let selectedGroupID else { return nil }
        return groups.first { $0.id == selectedGroupID }
    }

    // MARK: - Group selection / filter

    /// Selects a group for filtering; the Holder switches to S01
    /// `groupFiltered` state showing only cards assigned to that group.
    func selectGroup(_ id: UUID) {
        selectedGroupID = id
    }

    /// Clears the group filter, restoring the full Holder snapshot.
    func clearGroupFilter() {
        selectedGroupID = nil
    }

    // MARK: - Group card-selection workflow (transient)

    /// Begins the card-selection phase for group assignment.
    func beginGroupSelection() {
        groupCardSelection = []
    }

    /// Toggles a card's membership in the current selection.
    func toggleGroupCardSelection(_ cardID: UUID) {
        if groupCardSelection.contains(cardID) {
            groupCardSelection.remove(cardID)
        } else {
            groupCardSelection.insert(cardID)
        }
    }

    /// Clears the current card selection.
    func clearGroupCardSelection() {
        groupCardSelection = []
    }

    // MARK: - Create group

    /// Creates a new group with the given name and assigns it to all
    /// currently selected cards. Returns the created CardTag, or nil if
    /// the trimmed name is empty.
    @discardableResult
    func createGroup(named name: String) async -> CardTag? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let tag = CardTag(name: trimmed)
        await groupRepository.save(tag)

        // Assign the SAME CardTag value to every selected card.
        for cardID in groupCardSelection {
            guard var card = cards.first(where: { $0.id == cardID }) else {
                continue
            }
            // Do not duplicate the same group id on a card.
            if !card.tags.contains(where: { $0.id == tag.id }) {
                card.tags.append(tag)
            }
            card.updatedAt = Date()
            await repository.save(card)
        }

        // Refresh snapshots.
        await loadCards()
        await loadGroups()

        // Clear transient state.
        groupCardSelection = []
        pendingGroupName = ""

        return tag
    }

    // MARK: - Delete group

    /// Deletes a group from the catalog and removes it from all cards
    /// that carry it. Cards themselves are never deleted.
    func deleteGroup(id: UUID) async {
        // 1. Remove from catalog.
        await groupRepository.delete(id: id)

        // 2. Remove the tag from every card that carries it.
        for card in cards where card.tags.contains(where: { $0.id == id }) {
            var updated = card
            updated.tags.removeAll { $0.id == id }
            updated.updatedAt = Date()
            await repository.save(updated)
        }

        // 3. Refresh snapshots.
        await loadCards()
        await loadGroups()

        // 4. If the deleted group was the active filter, clear it.
        if selectedGroupID == id {
            selectedGroupID = nil
        }
    }

    // MARK: - Group count

    /// Number of cards currently assigned to the given group.
    /// Derived from the `cards` snapshot — no separate count storage.
    func cardCount(in groupID: UUID) -> Int {
        cards.filter { card in
            card.tags.contains { $0.id == groupID }
        }.count
    }
}
