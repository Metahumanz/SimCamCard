//
//  RuntimeStorageConfigurationTests.swift
//  SimCamCardTests
//
//  Tests for the DEBUG-only storage launch contract (T18):
//   - no argument → real persistent production layout (SimCamCard/v1);
//   - ephemeral → in-memory resolution, fixture seeds honored only here;
//   - persistent-test → isolated uitests/<namespace> layout; reset
//     wipes ONLY that namespace and never the production v1 data;
//   - namespace values are sanitized to one safe path component;
//   - unknown storage value falls back to production persistence.
//
//  These tests run against an injected temp Application Support
//  directory — the real container is never touched.
//

#if DEBUG

import Testing
import Foundation
@testable import SimCamCard

@Suite("RuntimeStorageConfiguration")
struct RuntimeStorageConfigurationTests {

    private func makeTempAppSupport() throws -> URL {
        try PersistenceTestSupport.makeUniqueTempDirectory(label: "simcamcard-appsupport")
    }

    private func persistentPaths(of resolution: RuntimeStorageResolution) -> PersistencePaths? {
        if case .persistent(let paths) = resolution { paths } else { nil }
    }

    @Test("no storage argument resolves to the production v1 layout")
    func defaultsToProductionPersistence() throws {
        let appSupport = try makeTempAppSupport()
        defer { PersistenceTestSupport.cleanup(appSupport) }

        let resolution = RuntimeStorageConfiguration.resolve(
            arguments: [],
            applicationSupportDirectory: appSupport
        )
        let paths = try #require(persistentPaths(of: resolution))
        #expect(paths.rootDirectory.pathComponents.suffix(2) == ["SimCamCard", "v1"])
    }

    @Test("unknown storage value resolves to production persistence")
    func unknownValueFallsBackToProduction() throws {
        let appSupport = try makeTempAppSupport()
        defer { PersistenceTestSupport.cleanup(appSupport) }

        let resolution = RuntimeStorageConfiguration.resolve(
            arguments: ["-SimCamCardStorage", "bogus"],
            applicationSupportDirectory: appSupport
        )
        let paths = try #require(persistentPaths(of: resolution))
        #expect(paths.rootDirectory.pathComponents.suffix(2) == ["SimCamCard", "v1"])
    }

    @Test("ephemeral without a fixture carries no seed cards")
    func ephemeralWithoutFixtureHasNoSeeds() throws {
        let appSupport = try makeTempAppSupport()
        defer { PersistenceTestSupport.cleanup(appSupport) }

        guard case .ephemeral(let seedCards) = RuntimeStorageConfiguration.resolve(
            arguments: ["-SimCamCardStorage", "ephemeral"],
            applicationSupportDirectory: appSupport
        ) else {
            Issue.record("expected ephemeral resolution")
            return
        }
        #expect(seedCards.isEmpty)
    }

    @Test("fixture cards are seeded only in ephemeral mode")
    func fixturesSeedEphemeralMode() throws {
        let appSupport = try makeTempAppSupport()
        defer { PersistenceTestSupport.cleanup(appSupport) }

        guard case .ephemeral(let populated) = RuntimeStorageConfiguration.resolve(
            arguments: ["-SimCamCardStorage", "ephemeral", "-SimCamCardFixture", "populated"],
            applicationSupportDirectory: appSupport
        ) else {
            Issue.record("expected ephemeral resolution")
            return
        }
        #expect(populated.count == MockBusinessCards.all.count)
        #expect(populated.count >= 1)

        guard case .ephemeral(let single) = RuntimeStorageConfiguration.resolve(
            arguments: ["-SimCamCardStorage", "ephemeral", "-SimCamCardFixture", "single"],
            applicationSupportDirectory: appSupport
        ) else {
            Issue.record("expected ephemeral resolution")
            return
        }
        #expect(single.count == MockBusinessCards.single.count)
        #expect(single.count == 1)
    }

    @Test("persistent-test resolves to an isolated namespaced layout, never v1")
    func persistentTestUsesIsolatedNamespace() throws {
        let appSupport = try makeTempAppSupport()
        defer { PersistenceTestSupport.cleanup(appSupport) }

        let resolution = RuntimeStorageConfiguration.resolve(
            arguments: [
                "-SimCamCardStorage", "persistent-test",
                "-SimCamCardStorageNamespace", "w4i9-unit",
                "-SimCamCardResetStorage", "false",
            ],
            applicationSupportDirectory: appSupport
        )
        let paths = try #require(persistentPaths(of: resolution))
        #expect(paths.rootDirectory.pathComponents.suffix(3) == ["SimCamCard", "uitests", "w4i9-unit"])
        #expect(paths.rootDirectory.pathComponents.contains("v1") == false)
    }

    @Test("reset true wipes only the namespace; v1 and other namespaces survive")
    func resetWipesOnlyNamespace() throws {
        let appSupport = try makeTempAppSupport()
        defer { PersistenceTestSupport.cleanup(appSupport) }

        let ns = "w4i9-reset"
        let namespaceRoot = appSupport
            .appendingPathComponent("SimCamCard/uitests/\(ns)", isDirectory: true)
        let productionRoot = appSupport
            .appendingPathComponent("SimCamCard/v1", isDirectory: true)
        let otherNamespace = appSupport
            .appendingPathComponent("SimCamCard/uitests/other-suite", isDirectory: true)
        try FileManager.default.createDirectory(at: namespaceRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: productionRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: otherNamespace, withIntermediateDirectories: true)

        let sentinel = namespaceRoot.appendingPathComponent("old-cards.json")
        try Data("old".utf8).write(to: sentinel)
        let productionSentinel = productionRoot.appendingPathComponent("real-user.json")
        try Data("real".utf8).write(to: productionSentinel)
        let otherSentinel = otherNamespace.appendingPathComponent("keep.json")
        try Data("keep".utf8).write(to: otherSentinel)

        _ = RuntimeStorageConfiguration.resolve(
            arguments: [
                "-SimCamCardStorage", "persistent-test",
                "-SimCamCardStorageNamespace", ns,
                "-SimCamCardResetStorage", "true",
            ],
            applicationSupportDirectory: appSupport
        )

        #expect(FileManager.default.fileExists(atPath: sentinel.path) == false)
        #expect(FileManager.default.fileExists(atPath: productionSentinel.path))
        #expect(FileManager.default.fileExists(atPath: otherSentinel.path))
    }

    @Test("reset false preserves existing namespace contents")
    func resetFalsePreservesNamespace() throws {
        let appSupport = try makeTempAppSupport()
        defer { PersistenceTestSupport.cleanup(appSupport) }
        let ns = "w4i9-keep"
        let namespaceRoot = appSupport
            .appendingPathComponent("SimCamCard/uitests/\(ns)", isDirectory: true)
        try FileManager.default.createDirectory(at: namespaceRoot, withIntermediateDirectories: true)
        let sentinel = namespaceRoot.appendingPathComponent("cards.json")
        try Data("{}".utf8).write(to: sentinel)

        _ = RuntimeStorageConfiguration.resolve(
            arguments: [
                "-SimCamCardStorage", "persistent-test",
                "-SimCamCardStorageNamespace", ns,
                "-SimCamCardResetStorage", "false",
            ],
            applicationSupportDirectory: appSupport
        )
        #expect(FileManager.default.fileExists(atPath: sentinel.path))
    }

    @Test("namespace is sanitized to one safe path component; missing becomes default")
    func namespaceSanitization() {
        let args: (String) -> [String] = { name in
            ["-SimCamCardStorage", "persistent-test", "-SimCamCardStorageNamespace", name]
        }
        let sanitized = RuntimeStorageConfiguration.parseNamespace(arguments: args("a/b 🔒x"))
        #expect(sanitized.contains("/") == false)
        #expect(sanitized.contains(" ") == false)
        #expect(sanitized.isEmpty == false)

        #expect(RuntimeStorageConfiguration.parseNamespace(arguments: args("---")) == "---")
        #expect(
            RuntimeStorageConfiguration.parseNamespace(
                arguments: ["-SimCamCardStorage", "persistent-test"]
            ) == "default"
        )
        // A value that happens to start with "-" is treated as absent.
        #expect(
            RuntimeStorageConfiguration.parseNamespace(arguments: args("-anotherFlag")) == "default"
        )
    }

    @Test("reset flag parses true/false values, bare presence, and absence")
    func resetFlagParsing() {
        #expect(RuntimeStorageConfiguration.parseReset(
            arguments: ["-SimCamCardResetStorage", "true"]) == true)
        #expect(RuntimeStorageConfiguration.parseReset(
            arguments: ["-SimCamCardResetStorage", "1"]) == true)
        #expect(RuntimeStorageConfiguration.parseReset(
            arguments: ["-SimCamCardResetStorage", "false"]) == false)
        #expect(RuntimeStorageConfiguration.parseReset(
            arguments: ["-SimCamCardResetStorage", "0"]) == false)
        #expect(RuntimeStorageConfiguration.parseReset(
            arguments: ["-SimCamCardResetStorage"]) == true)
        #expect(RuntimeStorageConfiguration.parseReset(arguments: []) == false)
    }
}

#endif
