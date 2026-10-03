//
//  InMemoryImageAssetStoreTests.swift
//  SimCamCardTests
//
//  Week 4 Increment 4 — ImageAssetStore in-memory implementation tests.
//
//  Verifies the storage contract the T12 save path relies on: byte-exact
//  round-trip, idempotent re-save, per-reference isolation and
//  concurrency safety. On-disk persistence (T18) is introduced behind
//  the same abstraction later.
//

import Foundation
import Testing
@testable import SimCamCard

struct InMemoryImageAssetStoreTests {

    @Test("save then data(for:) returns the same bytes")
    func saveThenLoadRoundTrips() async {
        let store = InMemoryImageAssetStore()
        let bytes = Data([0x01, 0x02, 0x03])
        await store.save(reference: "ref-a", data: bytes)
        #expect(await store.data(for: "ref-a") == bytes)
    }

    @Test("unknown reference returns nil")
    func unknownReferenceReturnsNil() async {
        let store = InMemoryImageAssetStore()
        #expect(await store.data(for: "missing") == nil)
    }

    @Test("re-saving a reference replaces the bytes (idempotent)")
    func resaveReplaces() async {
        let store = InMemoryImageAssetStore()
        await store.save(reference: "ref-a", data: Data([0x01]))
        await store.save(reference: "ref-a", data: Data([0x02]))
        #expect(await store.data(for: "ref-a") == Data([0x02]))
    }

    @Test("references are isolated from each other")
    func referencesAreIsolated() async {
        let store = InMemoryImageAssetStore()
        await store.save(reference: "ref-a", data: Data([0x0A]))
        await store.save(reference: "ref-b", data: Data([0x0B]))
        #expect(await store.data(for: "ref-a") == Data([0x0A]))
        #expect(await store.data(for: "ref-b") == Data([0x0B]))
    }

    @Test("concurrent saves all persist (actor serialization)")
    func concurrentSavesAllPersist() async {
        let store = InMemoryImageAssetStore()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<16 {
                group.addTask {
                    await store.save(reference: "ref-\(index)", data: Data([UInt8(index)]))
                }
            }
        }
        for index in 0..<16 {
            #expect(await store.data(for: "ref-\(index)") == Data([UInt8(index)]))
        }
    }
}
