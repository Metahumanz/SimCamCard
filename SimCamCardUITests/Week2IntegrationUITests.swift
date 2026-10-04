//
//  Week2IntegrationUITests.swift
//  SimCamCardUITests
//
//  Week 2 Increment 7 — Integration / Regression smoke test.
//
//  Verifies the full Week 2 navigation skeleton in a single app session
//  using the populated deterministic fixture:
//
//    Holder → Detail → Holder → Scanner → Holder
//
//  No OCR, Save, Camera, Search, Groups, persistence or mutation is
//  exercised. The test proves that the three Increments 3–6 compose
//  into one stable navigation graph and that holder state is preserved
//  across the round trip.
//
//  Spec sources:
//   - spec/page-inventory.md P01 / P02 / P07
//   - spec/state-inventory.md S01 / S02 / S06
//   - spec/reference-tests.md T01 / T02 / T13
//

import XCTest

final class Week2IntegrationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Fixture identifiers (mirror MockBusinessCards.swift)

    private let card001RowID = "card-row-00000000-0000-0000-0000-000000000001"
    private let card001Name = "张伟"
    private let card001Company = "上海智云科技有限公司"

    @MainActor
    func testWeek2NavigationSkeletonPreservesHolderState() throws {
        // Populated holder fixture + DEBUG authorized-camera fixture so
        // the Scanner leg of the round trip enters preview UI state
        // without a native permission dialog (fixture-driven, not a real
        // camera/native-permission verification).
        let app = UITestAppFactory.launchEphemeral(arguments: [
            "-SimCamCardFixture", "populated",
            "-SimCamCardCamera", "authorized"
        ])

        // 1. Populated Card Holder is visible.
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Populated Card Holder should be visible after launch."
        )

        // 2. Tap card 001 → Card Detail.
        let card001Row = app.descendants(matching: .any)[card001RowID].firstMatch
        XCTAssertTrue(
            card001Row.waitForExistence(timeout: 10),
            "Card 001 row should exist in the populated holder."
        )
        card001Row.tap()

        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 10),
            "Card Detail should be pushed after tapping card 001."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail"].exists,
            "Card Detail root should exist."
        )
        XCTAssertTrue(
            app.staticTexts[card001Name].exists,
            "Card Detail should show the card name."
        )
        XCTAssertTrue(
            app.staticTexts[card001Company].exists,
            "Card Detail should show the card company."
        )

        // 3. System Back → Card Holder.
        let detailBackButton = app.navigationBars["名片详情"].buttons.element(boundBy: 0)
        XCTAssertTrue(detailBackButton.waitForExistence(timeout: 5))
        detailBackButton.tap()

        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Should return to Card Holder after Back from Detail."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[card001RowID].exists,
            "Card 001 row should still exist after returning from Detail."
        )

        // 4. Tap scan-entry → Scanner.
        let scanEntry = app.buttons["scan-entry"]
        XCTAssertTrue(
            scanEntry.waitForExistence(timeout: 10),
            "Scan entry should exist on the holder."
        )
        scanEntry.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-entry-view"].waitForExistence(timeout: 10),
            "Scanner root should appear after tapping scan entry."
        )

        // 5. Close → Card Holder.
        let scanClose = app.buttons["scan-close"]
        XCTAssertTrue(scanClose.waitForExistence(timeout: 5))
        scanClose.tap()

        let scannerRoot = app.descendants(matching: .any)["scan-entry-view"]
        let disappeared = NSPredicate(format: "exists == false")
        expectation(for: disappeared, evaluatedWith: scannerRoot, handler: nil)
        waitForExpectations(timeout: 10)

        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Should return to Card Holder after closing Scanner."
        )

        // 6. Holder state unchanged: card 001 still present.
        XCTAssertTrue(
            app.descendants(matching: .any)[card001RowID].exists,
            "Card 001 row should still exist after the full round trip."
        )

        // Validation screenshot of the populated holder after round trip.
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "week2-integration-holder-after-roundtrip"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
