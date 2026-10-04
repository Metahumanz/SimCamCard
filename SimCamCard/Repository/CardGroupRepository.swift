//
//  CardGroupRepository.swift
//  SimCamCard
//
//  Data-access abstraction for the user-defined group catalog.
//
//  Spec sources:
//   - spec/reference-tests.md T16 Groups/Tags
//   - spec/state-inventory.md S07 Group / Tag
//   - spec/page-inventory.md P09 Group Management
//
//  This catalog is distinct from BusinessCard.tags: `tags` represents
//  "card → assigned groups"; `CardGroupRepository` represents
//  "all groups defined by the user" so that a group exists even after
//  its last card is removed.
//
//  Swift 6 concurrency: same shape as BusinessCardRepository — the
//  protocol is nonisolated and all operations are async.
//

import Foundation

nonisolated protocol CardGroupRepository: Sendable {

    /// All user-defined groups. Ordering is implementation-defined.
    func allGroups() async -> [CardTag]

    /// Returns the group with the given stable id, or nil.
    func group(id: UUID) async -> CardTag?

    /// Inserts a new group, or replaces the existing group with the same id.
    func save(_ group: CardTag) async

    /// Removes the group with the given id. Safe no-op when absent.
    func delete(id: UUID) async
}
