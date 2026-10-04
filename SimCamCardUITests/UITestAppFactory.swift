//
//  UITestAppFactory.swift
//  SimCamCardUITests
//
//  Central launch construction for UI tests (Week 4 Increment 9, T18).
//
//  Every UI test launches through this factory so that test runs never
//  touch the app's real persistent Application Support container:
//
//   - ephemeral: in-memory storage for the process lifetime (all
//     pre-existing UI tests — fixture/camera/ocr behavior only).
//   - persistent(namespace:reset:): real File repositories under an
//     isolated DEBUG namespace, used ONLY by the T18 terminate/
//     relaunch persistence test. The first launch resets; the second
//     launch (after XCUIApplication.terminate()) passes reset:false.
//
//  All existing fixture / camera / detection / crop / OCR launch
//  arguments are passed through verbatim via `arguments`.
//

import XCTest

enum UITestAppFactory {

    static let storageArgument = "-SimCamCardStorage"
    static let namespaceArgument = "-SimCamCardStorageNamespace"
    static let resetArgument = "-SimCamCardResetStorage"

    static let ephemeralStorageValue = "ephemeral"
    static let persistentStorageValue = "persistent-test"

    /// Builds an app configured for ephemeral (in-memory) storage.
    @MainActor
    static func makeEphemeral(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [storageArgument, ephemeralStorageValue] + arguments
        return app
    }

    /// Builds AND launches an ephemeral app.
    @discardableResult
    @MainActor
    static func launchEphemeral(arguments: [String] = []) -> XCUIApplication {
        let app = makeEphemeral(arguments: arguments)
        app.launch()
        return app
    }

    /// Builds an app backed by real File persistence under an isolated
    /// DEBUG namespace (…/SimCamCard/uitests/<namespace>/).
    /// - Parameters:
    ///   - namespace: stable per-scenario namespace.
    ///   - reset: true wipes the namespace before THIS launch (first
    ///     launch only); the post-relaunch launch must pass false.
    ///   - arguments: additional fixture/camera/crop/OCR arguments
    ///     (first launch of a persistence scenario may drive the
    ///     scanner with DEBUG fakes; the relaunch passes none).
    @MainActor
    static func makePersistent(
        namespace: String,
        reset: Bool,
        arguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            storageArgument, persistentStorageValue,
            namespaceArgument, namespace,
            resetArgument, reset ? "true" : "false",
        ] + arguments
        return app
    }

    /// Builds AND launches a persistent app.
    @discardableResult
    @MainActor
    static func launchPersistent(
        namespace: String,
        reset: Bool,
        arguments: [String] = []
    ) -> XCUIApplication {
        let app = makePersistent(namespace: namespace, reset: reset, arguments: arguments)
        app.launch()
        return app
    }
}
