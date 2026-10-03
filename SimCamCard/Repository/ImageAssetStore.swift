//
//  ImageAssetStore.swift
//  SimCamCard
//
//  Week 4 Increment 4 — image asset storage abstraction (T12 Save).
//
//  The frozen Domain Model (spec/data-model.md §BusinessCard) stores the
//  original / processed image as REQUIRED String reference tokens, never
//  as UIImage / Data. This store is the bridge between those tokens and
//  the real image bytes produced by the recognition pipeline
//  (CardCropResult.original.data + processedImageData).
//
//  Mirrors the BusinessCardRepository design:
//   - ViewModels / Views depend on the protocol, never a concrete store.
//   - In-memory implementation for this increment; on-disk persistence
//     (T18, spec/data-model.md §Persistence rule) is introduced behind
//     the same abstraction later.
//   - `nonisolated` + `async` so conforming types may be actor-isolated.
//

import Foundation

nonisolated protocol ImageAssetStore: Sendable {

    /// Persists image bytes under the given reference token. A repeated
    /// reference replaces the previously stored bytes (idempotent save —
    /// re-saving a card never duplicates its assets).
    func save(reference: String, data: Data) async

    /// Returns the image bytes stored under the given reference token,
    /// or nil when no asset exists for it (e.g. Week 2 seed fixtures whose
    /// "card-00x-original" tokens were never backed by real bytes).
    func data(for reference: String) async -> Data?
}

/// In-memory image asset storage. Data exists only for the process
/// lifetime; real on-disk persistence is deferred (T18) behind the same
/// ImageAssetStore abstraction, exactly like the card repository.
actor InMemoryImageAssetStore: ImageAssetStore {

    private var assets: [String: Data] = [:]

    func save(reference: String, data: Data) {
        assets[reference] = data
    }

    func data(for reference: String) -> Data? {
        assets[reference]
    }
}
