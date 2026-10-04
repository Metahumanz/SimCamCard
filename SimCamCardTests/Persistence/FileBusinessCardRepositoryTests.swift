//
//  FileBusinessCardRepositoryTests.swift
//  SimCamCardTests
//
//  T18 persistence tests for FileBusinessCardRepository.
//
//  The core proof pattern (spec/reference-tests.md T18,
//  spec/state-inventory.md S10): after writing through one repository
//  instance, discard it and construct a BRAND-NEW instance over the
//  same file URL. Restoration through the new instance proves the
//  state is on disk — a still-live object would prove nothing.
//
//  Coverage: absent-file emptiness (and no file created by init),
//  save/reload full equality, same-id replace across instances,
//  delete across instances, absent delete no-op, multiple cards,
//  corrected-field edit flow with stable ids, rawOCR, notes, tags,
//  both image references and timestamps.
//
//  Ordering note: allCards() ordering is implementation-defined;
//  multi-card cases assert SET membership only.
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("FileBusinessCardRepository")
struct FileBusinessCardRepositoryTests {

    // MARK: - Absent file

    @Test("a fresh store over an absent file is empty and creates no file")
    func emptyWhenFileAbsent() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)
        try FileManager.default.removeItem(at: dir) // ensure root absent too

        let repo = FileBusinessCardRepository(paths: paths)

        #expect(await repo.allCards().isEmpty)
        #expect(await repo.card(id: UUID()) == nil)
        #expect(FileManager.default.fileExists(atPath: paths.cardsFile.path) == false)
    }

    // MARK: - Save → NEW instance → restore

    @Test("saved max-info card is restored identically via a new instance")
    func saveRestoredViaNewInstance() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)
        let card = PersistenceTestSupport.makeMaxInfoCard()

        await FileBusinessCardRepository(paths: paths).save(card)
        #expect(FileManager.default.fileExists(atPath: paths.cardsFile.path))

        let reloaded = FileBusinessCardRepository(paths: paths) // simulate relaunch
        let cards = await reloaded.allCards()
        #expect(cards.count == 1)
        #expect(cards.first == card)
        #expect(await reloaded.card(id: card.id) == card)

        // Field-level S10 preservation on the reloaded value.
        let restored = try #require(cards.first)
        #expect(restored.originalImageReference == card.originalImageReference)
        #expect(restored.processedImageReference == card.processedImageReference)
        #expect(restored.rawOCRText == card.rawOCRText)
        #expect(restored.name == "张伟")
        #expect(restored.company == "上海智云科技有限公司")
        #expect(restored.jobTitle == "高级产品总监 | Senior Product Director")
        #expect(restored.website == "www.zhiyuntech.com")
        #expect(restored.address == "上海市浦东新区世纪大道100号 200120")
        #expect(restored.phones == card.phones)
        #expect(restored.emails == card.emails)
        #expect(restored.tags == card.tags)
        #expect(restored.notes == card.notes)
        #expect(restored.createdAt == card.createdAt)
        #expect(restored.updatedAt == card.updatedAt)
    }

    // MARK: - Same-id replace across instances (T14 edit flow)

    @Test("replacing the same id across reload yields one corrected card with stable ids")
    func replaceSameIDAcrossInstances() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)

        let original = PersistenceTestSupport.makeMaxInfoCard()
        await FileBusinessCardRepository(paths: paths).save(original)

        // Simulate the T14 saved-card edit flow: correct the job title,
        // change one phone value keeping its id, drop a tag, touch
        // updatedAt — BusinessCard.id and all stable metadata survive.
        var edited = original
        edited.jobTitle = "产品总监 | Product Director"
        edited.phones[0].value = "+86 138 0013 9999"
        edited.updatedAt = Date(timeIntervalSince1970: 1_700_000_999.001)
        await FileBusinessCardRepository(paths: paths).save(edited)

        let reloaded = FileBusinessCardRepository(paths: paths)
        let cards = await reloaded.allCards()
        #expect(cards.count == 1)
        let restored = try #require(cards.first)
        #expect(restored == edited)
        #expect(restored.id == original.id)
        #expect(restored.jobTitle == "产品总监 | Product Director")
        #expect(restored.phones[0].id == original.phones[0].id)
        #expect(restored.phones[0].value == "+86 138 0013 9999")
        #expect(restored.phones.count == original.phones.count)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == edited.updatedAt)
        #expect(restored.originalImageReference == original.originalImageReference)
    }

    // MARK: - Delete across instances

    @Test("delete removes the card for a new instance; absent delete is a safe no-op")
    func deleteAcrossInstances() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)
        let card = PersistenceTestSupport.makeMaxInfoCard()

        let writer = FileBusinessCardRepository(paths: paths)
        await writer.save(card)
        await writer.delete(id: card.id)

        let reloaded = FileBusinessCardRepository(paths: paths)
        #expect(await reloaded.allCards().isEmpty)
        #expect(await reloaded.card(id: card.id) == nil)

        // Deleting an absent id must not corrupt the document.
        await reloaded.delete(id: UUID())
        let again = FileBusinessCardRepository(paths: paths)
        #expect(await again.allCards().isEmpty)
    }

    // MARK: - Multiple cards (set membership, no order dependency)

    @Test("multiple saved cards restore as the same identity set via a new instance")
    func multipleCardsRestoreAsSet() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let paths = PersistencePaths(rootDirectory: dir)

        let a = BusinessCard(
            id: UUID(uuidString: "A1B2C3D4-0003-0003-0003-000000000001")!,
            originalImageReference: "a-original",
            processedImageReference: "a-processed",
            name: "甲",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let b = BusinessCard(
            id: UUID(uuidString: "A1B2C3D4-0003-0003-0003-000000000002")!,
            originalImageReference: "b-original",
            processedImageReference: "b-processed",
            rawOCRText: "raw-b",
            name: "乙",
            notes: [CardNote(
                id: UUID(uuidString: "D1B2C3D4-0003-0003-0003-000000000001")!,
                text: "备注 B",
                createdAt: Date(timeIntervalSince1970: 1_700_000_050)
            )],
            createdAt: Date(timeIntervalSince1970: 1_700_000_001),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_001)
        )

        let writer = FileBusinessCardRepository(paths: paths)
        await writer.save(a)
        await writer.save(b)

        let reloaded = FileBusinessCardRepository(paths: paths)
        let cards = await reloaded.allCards()
        #expect(Set(cards.map(\.id)) == [a.id, b.id])
        #expect(await reloaded.card(id: a.id) == a)
        #expect(await reloaded.card(id: b.id) == b)
    }
}
