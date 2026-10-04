//
//  RuntimeStorageConfiguration.swift
//  SimCamCard
//
//  Week 4 Increment 9 — DEBUG-only storage backend selection (T18).
//
//  This file is compiled ENTIRELY out of Release builds (#if DEBUG),
//  mirroring SimCamCardFixture / DebugCameraFakes: production builds
//  always use the real persistent File repositories under
//  Application Support/SimCamCard/v1 and contain none of the launch
//  argument strings parsed here.
//
//  DEBUG launch contract:
//
//   1. No `-SimCamCardStorage` argument (normal DEBUG manual launch):
//      REAL persistent storage → development/Release parity.
//
//   2. `-SimCamCardStorage ephemeral`:
//      InMemory trio. `-SimCamCardFixture populated|single` seeds
//      these in-memory repositories ONLY; mock cards are never written
//      to disk.
//
//   3. `-SimCamCardStorage persistent-test`
//        [-SimCamCardStorageNamespace <name>]
//        [-SimCamCardResetStorage <true|false>]
//      File repositories under an ISOLATED namespace
//      (…/SimCamCard/uitests/<name>/) which never overlaps production
//      v1. `…ResetStorage true` wipes that namespace before the FIRST
//      launch only; the post-relaunch launch passes false.
//
//  The composition root maps this resolution onto concrete stores;
//  ViewModels and Views continue to see only the frozen protocols.
//

#if DEBUG

import Foundation

/// Result of resolving the DEBUG launch arguments to a storage backend.
nonisolated enum RuntimeStorageResolution: Sendable {
    /// In-memory stores for the process lifetime, optionally seeded
    /// with deterministic fixture cards.
    case ephemeral(seedCards: [BusinessCard])
    /// Real File stores rooted at `paths`.
    case persistent(PersistencePaths)
}

nonisolated enum RuntimeStorageConfiguration {

    static let storageArgument = "-SimCamCardStorage"
    static let namespaceArgument = "-SimCamCardStorageNamespace"
    static let resetArgument = "-SimCamCardResetStorage"

    static let ephemeralValue = "ephemeral"
    static let persistentTestValue = "persistent-test"

    /// Resolves the current launch to a storage backend.
    ///
    /// - Parameters:
    ///   - arguments: launch arguments (defaults to the process arguments).
    ///   - applicationSupportDirectory: injectable Application Support
    ///     root; defaults to the real container. Unit tests may inject
    ///     a temp directory. Never nil in real launches.
    static func resolve(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        applicationSupportDirectory: URL? = nil
    ) -> RuntimeStorageResolution {
        let appSupport = applicationSupportDirectory
            ?? PersistencePaths.defaultApplicationSupportDirectory()
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        guard let index = arguments.firstIndex(of: storageArgument),
              index + 1 < arguments.count
        else {
            // No storage argument: real persistent storage even in DEBUG
            // (manual launches behave exactly like Release).
            return .persistent(PersistencePaths.production(
                applicationSupportDirectory: appSupport
            ))
        }

        switch arguments[index + 1] {
        case ephemeralValue:
            // Fixture selection (-SimCamCardFixture populated|single) is
            // read from the SAME argument list; seeds apply to the
            // in-memory stores only and are never written to disk.
            return .ephemeral(seedCards: SimCamCardFixture.initialCards(arguments: arguments))

        case persistentTestValue:
            let namespace = parseNamespace(arguments: arguments)
            let paths = PersistencePaths.persistentTest(
                applicationSupportDirectory: appSupport,
                namespace: namespace
            )
            if parseReset(arguments: arguments) {
                // First launch of a persistence test run: start from a
                // clean namespace. Scoped to uitests/<namespace> only.
                try? FileManager.default.removeItem(at: paths.rootDirectory)
            }
            return .persistent(paths)

        default:
            // Unknown value: never silently fall into test storage.
            return .persistent(PersistencePaths.production(
                applicationSupportDirectory: appSupport
            ))
        }
    }

    // MARK: - Argument parsing

    /// Reads `-SimCamCardStorageNamespace <name>` and reduces it to a
    /// single safe path component (letters, digits, `-`, `_`; anything
    /// else replaced with `-`). Missing/empty → `default`. The
    /// sanitization guarantees a namespace can never escape
    /// `…/SimCamCard/uitests/`.
    ///
    /// A following token shaped like another launch flag ("-" immediately
    /// followed by a letter, e.g. `-anotherFlag`) means the value was
    /// omitted → `default`. Punctuation-only tokens such as `---` are
    /// treated as ordinary values and sanitized, not as flags.
    static func parseNamespace(arguments: [String]) -> String {
        guard let index = arguments.firstIndex(of: namespaceArgument),
              index + 1 < arguments.count
        else {
            return "default"
        }
        let raw = arguments[index + 1]
        if raw.hasPrefix("-"), raw.dropFirst().first?.isLetter == true {
            return "default"
        }
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        let sanitized = String(raw.map { allowed.contains($0) ? $0 : "-" })
        return sanitized.isEmpty ? "default" : sanitized
    }

    /// Reads `-SimCamCardResetStorage <true|false>`. Accepts
    /// true/1/false/0; a bare flag (no following value) means true;
    /// absent means false.
    static func parseReset(arguments: [String]) -> Bool {
        guard let index = arguments.firstIndex(of: resetArgument) else {
            return false
        }
        guard index + 1 < arguments.count, !arguments[index + 1].hasPrefix("-") else {
            return true // bare flag presence = reset requested
        }
        switch arguments[index + 1].lowercased() {
        case "true", "1":
            return true
        case "false", "0":
            return false
        default:
            return false
        }
    }
}

#endif
