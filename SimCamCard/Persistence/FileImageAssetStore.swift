//
//  FileImageAssetStore.swift
//  SimCamCard
//
//  Week 4 Increment 9 — disk-backed ImageAssetStore (T18).
//
//  Image bytes (original + processed) are stored as opaque files under
//  the store's images/ directory. The Domain keeps only String
//  reference tokens; this store bridges tokens ↔ bytes, exactly like
//  InMemoryImageAssetStore but across terminate/relaunch.
//
//  Filename safety: a reference token is arbitrary user-space text and
//  may contain spaces, "/", "+" or Unicode. It is NEVER interpolated
//  into a path directly. Its UTF-8 bytes are Base64-encoded and then
//  converted to a URL/filename-safe Base64URL token:
//      "+" → "-", "/" → "_", "=" padding stripped, then ".asset".
//  Base64 is injective over distinct inputs, so distinct references
//  never collide; slashes and path traversal cannot escape images/.
//
//  Writes are atomic and lazy-create the directory; a repeated
//  reference replaces the bytes; a missing asset reads back as nil.
//
//  No deletion API is added to the frozen ImageAssetStore protocol
//  this increment. Orphaned bytes after a card delete are allowed and
//  recorded as future cleanup (they never leak into the UI because no
//  card references them).
//
//  Swift 6 concurrency: actor; files are independent and each write is
//  atomic.
//

import Foundation

actor FileImageAssetStore: ImageAssetStore {

    private let imagesDirectory: URL

    init(paths: PersistencePaths) {
        self.imagesDirectory = paths.imagesDirectory
    }

    init(directory: URL) {
        self.imagesDirectory = directory
    }

    // MARK: - ImageAssetStore

    func save(reference: String, data: Data) {
        let fileURL = Self.fileURL(forReference: reference, in: imagesDirectory)
        do {
            try FileManager.default.createDirectory(
                at: imagesDirectory,
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Best-effort parity with the in-memory store's non-throwing
            // protocol; a failed save simply leaves no readable asset.
        }
    }

    func data(for reference: String) -> Data? {
        let fileURL = Self.fileURL(forReference: reference, in: imagesDirectory)
        return try? Data(contentsOf: fileURL)
    }

    // MARK: - Reference encoding (pure, nonisolated)

    /// Encodes an arbitrary reference token into a single safe filename.
    nonisolated static func fileName(forReference reference: String) -> String {
        let base64 = Data(reference.utf8).base64EncodedString()
        let base64URL = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "\(base64URL).asset"
    }

    private nonisolated static func fileURL(forReference reference: String, in directory: URL) -> URL {
        directory.appendingPathComponent(fileName(forReference: reference), isDirectory: false)
    }
}
