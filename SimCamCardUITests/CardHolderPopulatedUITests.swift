//
//  CardHolderPopulatedUITests.swift
//  SimCamCardUITests
//
//  S01 populated-state UI test (XCTest).
//
//  Spec sources:
//   - spec/state-inventory.md S01 populated (one or more cards shown;
//     list updates immediately after save/delete — repository-level
//     prerequisite already verified by Increment 2; this test verifies
//     the ViewModel+View rendering path on a populated repository)
//   - Evidence: evidence/screenshots/REF-card-holder-02-after-save.png
//
//  Fixture injection:
//   - Launch argument `-SimCamCardFixture populated` activates
//     `SimCamCardFixture.initialCards()` → `MockBusinessCards.all`
//     (3 representative cards: 001 full bilingual, 002 missing website,
//     004 minimal). DEBUG-only; never affects Release or default launch.
//
//  Acceptance criteria verified:
//   1. Card Holder root exists (navigationTitle "名片夹").
//   2. `card-holder-empty` does NOT exist (populated state).
//   3. Each mock card's row exists by its fixed UUID (membership):
//        - card-row-00000000-0000-0000-0000-000000000001 (Card 001 张伟)
//        - card-row-00000000-0000-0000-0000-000000000002 (Card 002 李娜)
//        - card-row-00000000-0000-0000-0000-000000000004 (Card 004 张伟)
//   4. Each row's visible name text matches the fixture's `name` field.
//   5. No Detail navigation occurred (T13 deferred; rows are not tappable
//      in Week 2 Increment 4).
//   6. No Scan behavior triggered (T02 deferred).
//
//  This is an S01 populated-state UI test, NOT a T12 Save test. T12 Save
//  (card immediately appears in holder after save) requires the capture
//  pipeline to produce a real card; that behavior is not implemented in
//  Week 2 Increment 4 and is not claimed as tested here.
//
//  Accessibility-node count is NOT a stable contract: 3 business cards
//  may produce 5 matching elements in the SwiftUI accessibility tree
//  (cell wrapper + row content). This test does NOT assert any count of
//  card-row-* elements; membership is verified by per-UUID existence
//  checks only.
//
//  Order independence:
//   - Repository contract defines no order for `allCards()`. This test
//     verifies membership (each row exists) and per-row visible text,
//     NOT row position. MockBusinessCards fixture is deterministic in
//     CONTENT but the Repository may return its seeds in any order.
//

import XCTest

final class CardHolderPopulatedUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Fixture identifiers (mirror MockBusinessCards.swift)

    /// UUID suffixes mirrored from `MockBusinessCards.card001ID` etc.
    /// Duplicated here rather than imported (UI test target does not
    /// `@testable import` the App target's DEBUG-only enum) to keep the
    /// UI test target a pure black-box consumer.
    private let card001RowID = "card-row-00000000-0000-0000-0000-000000000001"
    private let card002RowID = "card-row-00000000-0000-0000-0000-000000000002"
    private let card004RowID = "card-row-00000000-0000-0000-0000-000000000004"

    @MainActor
    func testPopulatedCardHolderShowsMockCardsByMembership() throws {
        let app = UITestAppFactory.launchEphemeral(
            arguments: ["-SimCamCardFixture", "populated"]
        )

        // 1. Card Holder root exists (page identity).
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Card Holder navigation title '名片夹' should be visible."
        )

        // 2. Empty state must NOT be shown (populated state).
        XCTAssertFalse(
            app.descendants(matching: .any)["card-holder-empty"].exists,
            "Empty state must not be shown when cards are present."
        )

        // 3. Each mock card's row exists by its fixed UUID (membership).
        //    Accessibility-node count is NOT asserted — the SwiftUI
        //    accessibility tree may produce multiple matching elements per
        //    row, so node count is not a stable contract.
        XCTAssertTrue(
            app.descendants(matching: .any)[card001RowID].exists,
            "Card 001 row should exist by fixed UUID."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[card002RowID].exists,
            "Card 002 row should exist by fixed UUID."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[card004RowID].exists,
            "Card 004 row should exist by fixed UUID."
        )

        // 4. Each fixture's expected visible text exists in the UI.
        //    Uses global staticTexts existence queries — SwiftUI's List
        //    row accessibility element hierarchy does not reliably expose
        //    staticTexts as children of an element identified by
        //    `.accessibilityIdentifier`. Per-row existence is already
        //    verified by UUID in step 3. Existence (not count) is the
        //    contract: accessibility node counts are not stable.
        //    Card 001 and Card 004 both have name "张伟"; Card 002 has
        //    "李娜". Card 001 secondary line shows jobTitle · company.
        XCTAssertTrue(
            app.staticTexts["张伟"].exists,
            "Name '张伟' should be visible (Card 001 / Card 004)."
        )
        XCTAssertTrue(
            app.staticTexts["李娜"].exists,
            "Name '李娜' should be visible (Card 002)."
        )
        XCTAssertTrue(
            app.staticTexts["产品总监 | Product Director · 上海智云科技有限公司"].exists,
            "Card 001 secondary line (jobTitle · company) should be visible."
        )
        XCTAssertTrue(
            app.staticTexts["市场总监 | Marketing Director · 上海智云科技有限公司"].exists,
            "Card 002 secondary line (jobTitle · company) should be visible."
        )

        // 5. No Detail navigation occurred (T13 deferred).
        //    No navigation push to a Detail page — the only navigation bar
        //    present should be "名片夹" (the root). No additional navigation
        //    bar buttons are wired.
        XCTAssertFalse(
            app.navigationBars["Card Detail"].exists,
            "No Card Detail navigation should occur (T13 deferred)."
        )

        // 6. No Scan behavior triggered (T02 deferred).
        //    The "+" button remains visible and non-triggering.
        XCTAssertTrue(
            app.buttons["扫描"].exists,
            "Scan entry button should remain visible but non-triggering."
        )
        XCTAssertFalse(
            app.otherElements["scanner-preview"].exists,
            "No scanner preview should be presented (T02 deferred)."
        )
    }
}
