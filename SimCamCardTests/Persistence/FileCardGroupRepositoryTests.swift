//
//  FileCardGroupRepositoryTests.swift
//  SimCamCardTests
//
//  T18 persistence tests for FileCardGroupRepository.
//
//  Key S10/T16 point: groups.json is the AUTHORITATIVE catalog and is
//  independent of cards.json. A group to which ZERO cards are assigned
//  must persist on its own through terminate/relaunch (proved here via
//  a brand-new repository instance).
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("FileCardGroupRepository")
struct FileCardGroupRepositoryTests {

    private func makeGroup(_ id: String, _ name: String) -> CardTag {
        CardTag(id: UUID(uuidString: id)!, name: name)
    }

    @Test("an absent catalog reads empty and init creates no file")
    func emptyWhenFileAbsent() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)
        try FileManager.default.removeItem(at: dir)

        let repo = FileCardGroupRepository(paths: paths)
        #expect(await repo.allGroups().isEmpty)
        #expect(await repo.group(id: UUID()) == nil)
        #expect(FileManager.default.fileExists(atPath: paths.groupsFile.path) == false)
    }

    @Test("saved group is restored identically via a new instance")
    func saveRestoredViaNewInstance() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)
        let group = makeGroup("C1B2C3D4-0002-0002-0002-000000000001", "客户")

        await FileCardGroupRepository(paths: paths).save(group)

        let reloaded = FileCardGroupRepository(paths: paths)
        let groups = await reloaded.allGroups()
        #expect(groups == [group])
        #expect(await reloaded.group(id: group.id)?.name == "客户")
    }

    @Test("saving the same group id replaces it without duplicating")
    func replaceSameID() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)
        let id = UUID(uuidString: "C1B2C3D4-0003-0003-0003-000000000001")!

        let writer = FileCardGroupRepository(paths: paths)
        await writer.save(CardTag(id: id, name: "客户"))
        await writer.save(CardTag(id: id, name: "重点客户"))

        let reloaded = FileCardGroupRepository(paths: paths)
        let groups = await reloaded.allGroups()
        #expect(groups.count == 1)
        #expect(groups.first?.id == id)
        #expect(groups.first?.name == "重点客户")
    }

    @Test("multiple groups restore as a set via a new instance")
    func multipleGroupsRestoreAsSet() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)
        let g1 = makeGroup("C1B2C3D4-0004-0004-0004-000000000001", "客户")
        let g2 = makeGroup("C1B2C3D4-0004-0004-0004-000000000002", "供应商")

        let writer = FileCardGroupRepository(paths: paths)
        await writer.save(g1)
        await writer.save(g2)

        let reloaded = FileCardGroupRepository(paths: paths)
        #expect(Set(await reloaded.allGroups()) == [g1, g2])
    }

    @Test("delete removes the group for a new instance; absent delete is a no-op")
    func deleteAcrossInstances() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)
        let group = makeGroup("C1B2C3D4-0005-0005-0005-000000000001", "客户")

        let writer = FileCardGroupRepository(paths: paths)
        await writer.save(group)
        await writer.delete(id: group.id)

        let reloaded = FileCardGroupRepository(paths: paths)
        #expect(await reloaded.allGroups().isEmpty)
        await reloaded.delete(id: UUID()) // must not corrupt
        #expect(await FileCardGroupRepository(paths: paths).allGroups().isEmpty)
    }

    @Test("an empty group (zero assigned cards) persists independently")
    func emptyGroupPersistsIndependently() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)
        // No cards.json is ever written in this test — the catalog must
        // stand entirely on its own.
        let emptyGroup = makeGroup("C1B2C3D4-0006-0006-0006-000000000001", "潜在客户")

        await FileCardGroupRepository(paths: paths).save(emptyGroup)

        let reloaded = FileCardGroupRepository(paths: paths)
        #expect(await reloaded.allGroups() == [emptyGroup])
        #expect(await reloaded.group(id: emptyGroup.id) == emptyGroup)
        #expect(FileManager.default.fileExists(atPath: paths.groupsFile.path))
    }
}
