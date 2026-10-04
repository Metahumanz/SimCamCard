//
//  FileBusinessCardRepository.swift
//  SimCamCard
//
//  Week 4 Increment 9 — disk-backed BusinessCardRepository (T18).
//
//  Behavior mirrors the frozen protocol (identical semantics to
//  InMemoryBusinessCardRepository):
//   - allCards(): all stored cards (ordering is implementation-defined);
//   - card(id:): first match or nil;
//   - save(_:): insert-or-replace by id, never duplicates;
//   - delete(id:): safe no-op when absent.
//
//  Persistence proof model: every NEW repository instance reads the
//  file in its initializer. State restored via a freshly constructed
//  instance (after the old one was discarded) therefore proves
//  on-disk persistence — a still-live in-memory object proves nothing.
//
//  Mutation ordering: build next array → encode JSON → ensure parent
//  directory exists → atomic write → commit to the in-memory cache
//  only after the write succeeds. The previous document is never
//  truncated before its replacement is fully staged (Data.write
//  .atomic writes to a side file and renames).
//
//  Swift 6 concurrency: actor-isolated mutable state; no mutable
//  class, no locks, no @unchecked Sendable.
//

import Foundation

actor FileBusinessCardRepository: BusinessCardRepository {

    private let fileURL: URL

    /// In-memory mirror of the last successfully read/written document.
    /// Reads are served from here; it is replaced only after a
    /// successful atomic write.
    private var cards: [BusinessCard]

    /// Production/test initializer: cards live at `paths.cardsFile`.
    init(paths: PersistencePaths) {
        self.fileURL = paths.cardsFile
        self.cards = Self.loadCards(from: paths.cardsFile)
    }

    /// Convenience initializer pointing directly at a cards.json file
    /// (unit tests use unique temp files).
    init(fileURL: URL) {
        self.fileURL = fileURL
        self.cards = Self.loadCards(from: fileURL)
    }

    // MARK: - BusinessCardRepository

    func allCards() -> [BusinessCard] {
        cards
    }

    func card(id: UUID) -> BusinessCard? {
        cards.first { $0.id == id }
    }

    func save(_ card: BusinessCard) {
        var next = cards
        if let index = next.firstIndex(where: { $0.id == card.id }) {
            next[index] = card
        } else {
            next.append(card)
        }
        guard Self.write(next, to: fileURL) else {
            // Write failed: keep the cache matching the last known disk
            // state; the protocol offers no error surface for storage
            // failures (same best-effort contract as the in-memory store).
            return
        }
        cards = next
    }

    func delete(id: UUID) {
        var next = cards
        next.removeAll { $0.id == id }
        guard next.count != cards.count else {
            // Absent id: nothing removed → nothing to write (safe no-op).
            return
        }
        guard Self.write(next, to: fileURL) else { return }
        cards = next
    }

    // MARK: - Disk I/O (pure, nonisolated)

    private nonisolated static func loadCards(from fileURL: URL) -> [BusinessCard] {
        guard let data = try? Data(contentsOf: fileURL) else {
            // Absent file = first launch with an empty store.
            return []
        }
        guard let document = try? PersistenceJSON.decoder.decode(
            BusinessCardStoreDocument.self, from: data
        ) else {
            // Corrupt/unreadable document: fail safe with an empty view.
            // A later successful save replaces the file atomically.
            return []
        }
        return document.cards.map { $0.businessCard() }
    }

    /// Encodes and atomically writes the next generation. Returns false
    /// on any failure without touching the caller's cached state.
    private nonisolated static func write(_ cards: [BusinessCard], to fileURL: URL) -> Bool {
        let document = BusinessCardStoreDocument(cards: cards.map(BusinessCardSnapshot.init))
        guard let data = try? PersistenceJSON.encoder.encode(document) else {
            return false
        }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: [.atomic])
            return true
        } catch {
            return false
        }
    }
}
