//
//  InMemoryCardGroupRepositoryTests.swift
//  SimCamCardTests
//
//  Unit tests for InMemoryCardGroupRepository (Swift Testing).
//
//  Spec sources:
//   - spec/reference-tests.md T16 Groups/Tags
//   - spec/state-inventory.md S07 Group / Tag
//
//  Verifies:
//   - initial empty / initial groups supported
//   - save inserts / same id replaces / different ids coexist
//   - group(id:) lookup
//   - delete existing / delete missing no-op
//   - empty group can exist independently of cards
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("InMemoryCardGroupRepository")
struct InMemoryCardGroupRepositoryTests {

    private func makeGroup(id: UUID = UUID(), name: String = "Test") -> CardTag {
        CardTag(id: id, name: name)
    }

    @Test("initial state is empty")
    func initialEmpty() async {
        let repo = InMemoryCardGroupRepository()
        let groups = await repo.allGroups()
        #expect(groups.isEmpty)
    }

    @Test("initial groups are supported")
    func initialGroups() async {
        let g1 = makeGroup(name: "VIP")
        let g2 = makeGroup(name: "客户")
        let repo = InMemoryCardGroupRepository(initialGroups: [g1, g2])
        let groups = await repo.allGroups()
        #expect(groups.count == 2)
        #expect(Set(groups.map(\.id)) == [g1.id, g2.id])
    }

    @Test("save inserts a new group")
    func saveInserts() async {
        let repo = InMemoryCardGroupRepository()
        let group = makeGroup(name: "合作伙伴")
        await repo.save(group)
        let groups = await repo.allGroups()
        #expect(groups.count == 1)
        #expect(groups.first?.id == group.id)
    }

    @Test("save with same id replaces the existing group")
    func saveReplaces() async {
        let group = makeGroup(name: "Old Name")
        let repo = InMemoryCardGroupRepository(initialGroups: [group])
        let renamed = CardTag(id: group.id, name: "New Name")
        await repo.save(renamed)
        let groups = await repo.allGroups()
        #expect(groups.count == 1)
        #expect(groups.first?.name == "New Name")
    }

    @Test("different ids coexist")
    func differentIDsCoexist() async {
        let repo = InMemoryCardGroupRepository()
        let g1 = makeGroup(name: "A")
        let g2 = makeGroup(name: "B")
        await repo.save(g1)
        await repo.save(g2)
        let groups = await repo.allGroups()
        #expect(groups.count == 2)
        #expect(Set(groups.map(\.id)) == [g1.id, g2.id])
    }

    @Test("group(id:) returns the correct group")
    func groupByID() async {
        let g1 = makeGroup(name: "VIP")
        let g2 = makeGroup(name: "客户")
        let repo = InMemoryCardGroupRepository(initialGroups: [g1, g2])
        let found = await repo.group(id: g2.id)
        #expect(found?.name == "客户")
        let missing = await repo.group(id: UUID())
        #expect(missing == nil)
    }

    @Test("delete existing removes the group")
    func deleteExisting() async {
        let g1 = makeGroup(name: "VIP")
        let repo = InMemoryCardGroupRepository(initialGroups: [g1])
        await repo.delete(id: g1.id)
        let groups = await repo.allGroups()
        #expect(groups.isEmpty)
    }

    @Test("delete missing id is a safe no-op")
    func deleteMissingNoOp() async {
        let g1 = makeGroup(name: "VIP")
        let repo = InMemoryCardGroupRepository(initialGroups: [g1])
        await repo.delete(id: UUID())
        let groups = await repo.allGroups()
        #expect(groups.count == 1)
    }

    @Test("empty group exists independently of any card")
    func emptyGroupIndependentOfCards() async {
        let repo = InMemoryCardGroupRepository()
        let group = makeGroup(name: "Empty Group")
        await repo.save(group)
        let groups = await repo.allGroups()
        #expect(groups.count == 1)
        // No BusinessCard was involved — the catalog is self-contained.
    }
}
