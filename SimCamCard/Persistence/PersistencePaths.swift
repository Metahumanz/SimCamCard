//
//  PersistencePaths.swift
//  SimCamCard
//
//  Week 4 Increment 9 — on-disk storage layout for T18 Persistence.
//
//  Layout (all paths derived from one root directory so that a whole
//  store — cards, groups, images — can be relocated or wiped together):
//
//      <root>/
//        cards.json
//        groups.json
//        images/
//
//  Production root:
//      <Application Support>/SimCamCard/v1/
//
//  DEBUG persistent-test root (never overlaps production v1):
//      <Application Support>/SimCamCard/uitests/<namespace>/
//
//  Spec sources:
//   - spec/reference-tests.md T18 Persistence
//   - spec/state-inventory.md S10 Persistence
//   - spec/data-model.md §Persistence rule
//

import Foundation

/// Filesystem locations for one persistent store. A value type: the
/// File repositories each take the single file/directory URL they own.
///
/// Marked `nonisolated` because the App target defaults to MainActor
/// isolation; persistence value types must be usable from the File
/// repository actors and nonisolated disk helpers.
nonisolated struct PersistencePaths: Sendable {

    /// Root directory containing cards.json, groups.json and images/.
    let rootDirectory: URL

    init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    /// JSON document holding all BusinessCard records.
    var cardsFile: URL {
        rootDirectory.appendingPathComponent("cards.json", isDirectory: false)
    }

    /// JSON document holding the user-defined group catalog.
    var groupsFile: URL {
        rootDirectory.appendingPathComponent("groups.json", isDirectory: false)
    }

    /// Directory holding opaque image-asset files keyed by a safe
    /// encoding of their String reference token.
    var imagesDirectory: URL {
        rootDirectory.appendingPathComponent("images", isDirectory: true)
    }

    /// Production layout under the given Application Support directory:
    /// `<AppSupport>/SimCamCard/v1/`. The `v1` segment is the on-disk
    /// schema namespace; a future incompatible schema would use a new
    /// segment rather than mutating v1 data in place.
    static func production(applicationSupportDirectory: URL) -> PersistencePaths {
        let root = applicationSupportDirectory
            .appendingPathComponent("SimCamCard", isDirectory: true)
            .appendingPathComponent("v1", isDirectory: true)
        return PersistencePaths(rootDirectory: root)
    }

    /// DEBUG UI-test layout under an isolated namespace:
    /// `<AppSupport>/SimCamCard/uitests/<namespace>/`. Never overlaps
    /// the production `v1` root, so a test reset can never touch real
    /// user data (and vice versa).
    static func persistentTest(
        applicationSupportDirectory: URL,
        namespace: String
    ) -> PersistencePaths {
        let root = applicationSupportDirectory
            .appendingPathComponent("SimCamCard", isDirectory: true)
            .appendingPathComponent("uitests", isDirectory: true)
            .appendingPathComponent(namespace, isDirectory: true)
        return PersistencePaths(rootDirectory: root)
    }

    /// The user's Application Support directory. Computed lazily by
    /// callers (composition root / DEBUG configuration) so unit tests
    /// never touch the real container.
    static func defaultApplicationSupportDirectory(
        fileManager: FileManager = .default
    ) -> URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }
}
