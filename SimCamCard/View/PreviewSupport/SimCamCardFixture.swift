//
//  SimCamCardFixture.swift
//  SimCamCard
//
//  Launch-argument parser that selects deterministic mock fixtures for
//  DEBUG / UI-test runs.
//
//  Spec sources:
//   - Week 2 Increment 4 brief (Rev 2): "Mock data via DEBUG + launch
//     argument/environment deterministic fixture injection. Normal launch
//     = empty repo. UI-test-empty fixture vs UI-test-populated fixture.
//     Mock must NOT be release/default runtime data."
//
//  Contract:
//   - Normal launch (no `-SimCamCardFixture` argument, OR Release build):
//     returns `[]` → `InMemoryBusinessCardRepository()` is empty.
//   - `-SimCamCardFixture populated` (DEBUG + UI test opt-in):
//     returns `MockBusinessCards.all` → 3 representative cards seeded.
//   - `-SimCamCardFixture single` (DEBUG + UI test opt-in):
//     returns `MockBusinessCards.single` → 1 card seeded (matches
//     REF-card-holder-02-after-save.png — one card immediately after save).
//
//  Release builds compile this entire file out via `#if DEBUG` /
//  `#else`, so the Release `seedCards` path is a hardcoded `[]` with
//  zero references to `MockBusinessCards`. Mock fixtures never become
//  default runtime data.
//
//  This module does not modify the Domain Model, the Repository protocol,
//  or `InMemoryBusinessCardRepository` semantics; it only feeds
//  `initialCards:` into the existing initializer.
//

import Foundation

#if DEBUG
nonisolated enum SimCamCardFixture {

    /// Launch-argument flag that activates fixture selection.
    /// The "-…" prefix follows XCTest's launch-argument convention so
    /// the value is not interpreted as a URL scheme.
    static let launchArgument = "-SimCamCardFixture"

    /// Mode keyword that follows `-SimCamCardFixture` on the launch
    /// argument list (e.g. `["-SimCamCardFixture", "populated"]`).
    enum Mode: String {
        case populated
        case single
    }

    /// Returns the deterministic seed cards for the current launch
    /// arguments. `[]` when no fixture is requested.
    ///
    /// Default `arguments` source is `ProcessInfo.processInfo.arguments`,
    /// but tests / Previews may pass a custom list (e.g. for unit-testing
    /// the parser itself — not exercised in production code).
    static func initialCards(arguments: [String] = ProcessInfo.processInfo.arguments) -> [BusinessCard] {
        guard let index = arguments.firstIndex(of: launchArgument),
              index + 1 < arguments.count
        else {
            return []
        }
        switch arguments[index + 1] {
        case Mode.populated.rawValue:
            return MockBusinessCards.all
        case Mode.single.rawValue:
            return MockBusinessCards.single
        default:
            return []
        }
    }
}
#else
nonisolated enum SimCamCardFixture {

    /// Release build stub. Always returns `[]` — no mock fixture
    /// injection in Release. `MockBusinessCards` is compiled out under
    /// `#if DEBUG`, so this stub must not reference it.
    static func initialCards(arguments: [String] = []) -> [BusinessCard] {
        []
    }
}
#endif
