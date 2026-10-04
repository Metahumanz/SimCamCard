//
//  FileCardGroupRepository.swift
//  SimCamCard
//
//  Week 4 Increment 9 — disk-backed CardGroupRepository (T18).
//
//  groups.json is the AUTHORITATIVE group catalog. It is stored and
//  persisted independently of cards.json: a freshly created group to
//  which zero cards are assigned survives a full terminate/relaunch,
//  and deleting a group never deletes cards (the ViewModel performs
//  tag removal on cards through the card repository). The catalog is
//  NEVER rebuilt from the tag collections embedded in cards.
//
//  Mutation ordering matches FileBusinessCardRepository: build next →
//  encode → ensure directory → atomic write → commit cache.
//
//  Swift 6 concurrency: actor; no mutable class / locks /
//  @unchecked Sendable.
//

import Foundation

actor FileCardGroupRepository: CardGroupRepository {

    private let fileURL: URL

    private var groups: [CardTag]

    init(paths: PersistencePaths) {
        self.fileURL = paths.groupsFile
        self.groups = Self.loadGroups(from: paths.groupsFile)
    }

    init(fileURL: URL) {
        self.fileURL = fileURL
        self.groups = Self.loadGroups(from: fileURL)
    }

    // MARK: - CardGroupRepository

    func allGroups() -> [CardTag] {
        groups
    }

    func group(id: UUID) -> CardTag? {
        groups.first { $0.id == id }
    }

    func save(_ group: CardTag) {
        var next = groups
        if let index = next.firstIndex(where: { $0.id == group.id }) {
            next[index] = group
        } else {
            next.append(group)
        }
        guard Self.write(next, to: fileURL) else { return }
        groups = next
    }

    func delete(id: UUID) {
        var next = groups
        next.removeAll { $0.id == id }
        guard next.count != groups.count else { return } // absent: no-op
        guard Self.write(next, to: fileURL) else { return }
        groups = next
    }

    // MARK: - Disk I/O (pure, nonisolated)

    private nonisolated static func loadGroups(from fileURL: URL) -> [CardTag] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return [] // absent catalog = no user-defined groups yet
        }
        guard let document = try? PersistenceJSON.decoder.decode(
            CardGroupStoreDocument.self, from: data
        ) else {
            return []
        }
        return document.groups.map { $0.cardTag() }
    }

    private nonisolated static func write(_ groups: [CardTag], to fileURL: URL) -> Bool {
        let document = CardGroupStoreDocument(groups: groups.map(CardTagSnapshot.init))
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
