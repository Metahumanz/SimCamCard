//
//  CardTag.swift
//  SimCamCard
//
//  Domain value representing a tag/group attached to a business card.
//  Spec source: spec/data-model.md §BusinessCard (tags: collection)
//  Week 2 only defines the shape; tag/group management UI is deferred.
//

import Foundation

nonisolated struct CardTag: Identifiable, Sendable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
