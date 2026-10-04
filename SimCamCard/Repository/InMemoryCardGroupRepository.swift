//
//  InMemoryCardGroupRepository.swift
//  SimCamCard
//
//  Week 4 Increment 7 in-memory implementation of CardGroupRepository.
//
//  Same actor-based concurrency contract as
//  InMemoryBusinessCardRepository: mutable storage is serialized through
//  actor isolation; no mutable class, no locks, no @unchecked Sendable.
//

import Foundation

actor InMemoryCardGroupRepository: CardGroupRepository {

    /// Dictionary storage keyed by stable group id.
    private var groups: [UUID: CardTag]

    init(initialGroups: [CardTag] = []) {
        var seeded: [UUID: CardTag] = [:]
        for group in initialGroups {
            seeded[group.id] = group
        }
        self.groups = seeded
    }

    // MARK: - CardGroupRepository

    func allGroups() -> [CardTag] {
        Array(groups.values)
    }

    func group(id: UUID) -> CardTag? {
        groups[id]
    }

    func save(_ group: CardTag) {
        groups[group.id] = group
    }

    func delete(id: UUID) {
        groups[id] = nil
    }
}
