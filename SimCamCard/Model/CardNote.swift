//
//  CardNote.swift
//  SimCamCard
//
//  Domain value representing a note attached to a business card.
//  Spec source: spec/data-model.md §BusinessCard (notes: collection)
//  Week 2 only defines the shape; note add/edit UI is deferred.
//

import Foundation

nonisolated struct CardNote: Identifiable, Sendable, Hashable {
    let id: UUID
    var text: String
    let createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}
