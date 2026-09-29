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
//   5. No card-row / list-cell elements exist (empty state).
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

        // 5. No card-row / list-cell elements exist (empty state).
        //    The empty state shows ContentUnavailableView, not a List.
        //    No card-row identifier infrastructure exists yet (populated
        //    UI is deferred). Asserting zero table/collection cells.
        XCTAssertEqual(
            app.cells.count,
            0,
            "No card rows should be displayed in the empty state."
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
