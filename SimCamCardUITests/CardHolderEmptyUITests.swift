//
//  CardHolderEmptyUITests.swift
//  SimCamCardUITests
//
//  T01 — First Launch / Empty Holder UI test (XCTest).
//
//  Spec sources:
//   - spec/reference-tests.md T01: "Empty Card Holder is shown when no
//     cards exist."
//   - Evidence: evidence/screenshots/REF-card-holder-01-empty.png
//   - spec/state-inventory.md S01 empty (zero saved cards, scan entry
//     remains available)
//
//  Acceptance criteria verified:
//   1. Card Holder root exists (navigationTitle "名片夹").
//   2. "名片 (0张)" empty indicator is shown.
//   3. "card-holder-empty" accessibility identifier exists.
//   4. Scan entry CTA ("扫描" button) is visible.
//   5. No card-row-* accessibility identifiers exist (empty state).
//
//  This test verifies T01 BEHAVIORAL acceptance (empty holder shown when
//  no cards exist). Reference UI fidelity is PARTIAL — the current
//  ContentUnavailableView and toolbar "+" are Week 2 scaffolds, not
//  verified replicas of the Reference empty-state visual and header
//  "+" button.
//
//  This test does NOT verify T02 scanner navigation — that is deferred
//  to a later increment. The "+" button is a non-triggering element.
//
//  The empty state is verified via `card-row-*` absence (NSPredicate
//  identifier BEGINSWITH), the long-term contract for asserting no card
//  rows — not `app.cells.count`, which is a less stable cross-version
//  XCTest proxy.
//

import XCTest

final class CardHolderEmptyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEmptyCardHolderOnFirstLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Card Holder root exists (page identity).
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Card Holder navigation title '名片夹' should be visible on first launch."
        )

        // 2. "名片 (0张)" empty indicator is shown.
        XCTAssertTrue(
            app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS %@", "名片 (0张)")
            ).firstMatch.exists,
            "Empty indicator '名片 (0张)' should be visible."
        )

        // 3. "card-holder-empty" accessibility identifier exists.
        XCTAssertTrue(
            app.descendants(matching: .any)["card-holder-empty"].exists,
            "Empty state view with accessibilityIdentifier 'card-holder-empty' should exist."
        )

        // 4. Scan entry CTA is visible and accessible.
        XCTAssertTrue(
            app.buttons["扫描"].exists,
            "Scan entry button (accessibilityLabel '扫描') should be visible."
        )

        // 5. No card-row-* accessibility identifiers exist (empty state).
        //    Uses NSPredicate(identifier BEGINSWITH "card-row-") to assert
        //    the absence of ANY card row by stable contract — independent
        //    of XCTest cell-count proxies.
        let cardRowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "card-row-")
        let cardRowCount = app.descendants(matching: .any)
            .matching(cardRowPredicate)
            .count
        XCTAssertEqual(
            cardRowCount,
            0,
            "No card-row-* identifiers should exist in the empty state."
        )

        // 6. No development placeholder text.
        XCTAssertFalse(
            app.staticTexts["Coming soon"].exists,
            "No 'Coming soon' text should be displayed."
        )
        XCTAssertFalse(
            app.staticTexts["Not implemented"].exists,
            "No 'Not implemented' text should be displayed."
        )
    }
}
