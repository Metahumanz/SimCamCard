//
//  FileImageAssetStoreTests.swift
//  SimCamCardTests
//
//  T18 persistence tests for FileImageAssetStore.
//
//  Proof pattern matches the repositories: persistence is asserted via
//  a BRAND-NEW store instance over the same directory after the writer
//  is discarded. Covers exact-byte restoration, independent original/
//  processed references, same-reference replacement, missing asset
//  nil, lazy directory creation, and Base64URL filename safety for
//  references containing "/", spaces, "+", Unicode and traversal-ish
//  sequences (none may escape images/ or collide).
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("FileImageAssetStore")
struct FileImageAssetStoreTests {

    @Test("saved bytes reload exactly via a new store instance")
    func saveAndReloadExactBytes() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        // Production layout: assets under <root>/images/.
        let images = PersistencePaths(rootDirectory: dir).imagesDirectory

        let original = PersistenceTestSupport.originalImageBytes
        let processed = PersistenceTestSupport.processedImageBytes
        let writer = FileImageAssetStore(directory: images)
        await writer.save(reference: "card-001-original", data: original)
        await writer.save(reference: "card-001-processed", data: processed)

        let reloaded = FileImageAssetStore(directory: images) // new instance
        #expect(await reloaded.data(for: "card-001-original") == original)
        #expect(await reloaded.data(for: "card-001-processed") == processed)
    }

    @Test("original and processed references stay independent")
    func referencesAreIndependent() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let store = FileImageAssetStore(directory: dir)
        await store.save(reference: "same-card/original", data: Data([1, 2, 3]))
        await store.save(reference: "same-card/processed", data: Data([4, 5, 6]))

        #expect(await store.data(for: "same-card/original") == Data([1, 2, 3]))
        #expect(await store.data(for: "same-card/processed") == Data([4, 5, 6]))
    }

    @Test("re-saving a reference replaces the bytes")
    func replaceBytes() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let writer = FileImageAssetStore(directory: dir)
        await writer.save(reference: "ref", data: Data([1, 1, 1]))
        await writer.save(reference: "ref", data: Data([2, 2, 2]))

        let reloaded = FileImageAssetStore(directory: dir)
        #expect(await reloaded.data(for: "ref") == Data([2, 2, 2]))
        // Exactly one asset file for the one reference (no duplicate).
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(files.count == 1)
    }

    @Test("a missing reference reads nil")
    func missingReferenceIsNil() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let store = FileImageAssetStore(directory: dir)
        #expect(await store.data(for: "never-saved") == nil)
    }

    @Test("images directory is created lazily on first save")
    func lazyDirectoryCreation() async throws {
        let root = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(root) }
        let images = root.appendingPathComponent("images", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: images.path) == false)

        let store = FileImageAssetStore(directory: images)
        await store.save(reference: "r", data: Data([9]))

        #expect(FileManager.default.fileExists(atPath: images.path) == true)
        #expect(await store.data(for: "r") == Data([9]))
    }

    @Test("references with slashes/spaces/plus/unicode/traversal stay inside the directory")
    func unsafeReferencesAreEncodedSafely() async throws {
        let dir = try PersistenceTestSupport.makeUniqueTempDirectory()
        defer { PersistenceTestSupport.cleanup(dir) }
        let trickyReferences = [
            "a/b",
            "a_b",          // must NOT collide with the encoding of "a/b"
            "with space + plus",
            "卡片/原图 α",
            "../escape",
            "....//....",
        ]

        let writer = FileImageAssetStore(directory: dir)
        for (index, ref) in trickyReferences.enumerated() {
            await writer.save(reference: ref, data: Data([UInt8(index)]))
        }

        // Every encoded filename is a single flat component: no "/",
        // ends with .asset, lives directly in the store directory.
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(files.count == trickyReferences.count)
        for file in files {
            #expect(file.contains("/") == false)
            #expect(file.hasSuffix(".asset"))
            let full = dir.appendingPathComponent(file)
            // The file resolves strictly inside dir (no traversal escape).
            #expect(full.deletingLastPathComponent().standardizedFileURL.path == dir.standardizedFileURL.path)
        }

        // All bytes round-trip through a fresh instance → injectivity.
        let reloaded = FileImageAssetStore(directory: dir)
        for (index, ref) in trickyReferences.enumerated() {
            #expect(await reloaded.data(for: ref) == Data([UInt8(index)]))
        }

        // Explicit collision guard for the canonical slash/underscore pair.
        #expect(
            FileImageAssetStore.fileName(forReference: "a/b")
            != FileImageAssetStore.fileName(forReference: "a_b")
        )
    }
}
