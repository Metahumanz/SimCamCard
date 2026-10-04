//
//  CardDeleteUITests.swift
//  SimCamCardUITests
//
//  T17 — Delete flow UI tests (XCTest).
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail (Delete action)
//   - spec/state-inventory.md S06 `deleted`, S01 (list updates immediately
//     after delete; deleting the last card returns the Holder to empty)
//   - spec/reference-tests.md T17 Delete ("Confirmation precedes delete;
//     card disappears afterward.")
//   - Evidence: evidence/screenshots/REF-detail-04-more-actions.png,
//     evidence/screenshots/REF-delete-01-confirmation.png,
//     evidence/screenshots/REF-card-holder-01-empty.png
//
//  Real flow under test:
//   launch single fixture → open card 001 Detail → tap ••• more →
//   tap 删除 → native 「提示」 confirmation → tap 删除名片 →
//   repository delete → Holder reload → Detail pops → card 001 row is
//   absent and the empty Holder + scan entry are shown.
//
//  The Cancel case must leave the card completely unchanged: the Detail
//  stays on screen with the name visible and, after returning, the Holder
//  still lists card 001.
//
//  Fixture: `-SimCamCardFixture single` seeds MockBusinessCards.single
//  (card 001 only) so deleting it drives the last-card → empty-holder
//  branch (S01). DEBUG-only; no sleep — synchronization is via
//  waitForExistence / waitForNonExistence.
//

import XCTest

final class CardDeleteUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Fixture identifiers (mirror MockBusinessCards.swift)

    private let card001RowID = "card-row-00000000-0000-0000-0000-000000000001"

    private let moreButtonID = "card-detail-more"
    private let deleteActionID = "card-detail-delete"
    private let confirmButtonID = "card-delete-confirm"
    private let cancelButtonID = "card-delete-cancel"

    private let confirmTitle = "提示"
    private let confirmMessage = "删除未同步名片将无法恢复，请确认是否要删除？"
    private let confirmButtonLabel = "删除名片"
    private let deleteActionLabel = "删除"
    private let cancelLabel = "取消"

    /// Launches the app with the single-card deterministic fixture.
    @MainActor
    private func launchSingle() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-SimCamCardFixture", "single"]
        app.launch()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Card Holder should be visible after launch."
        )
        return app
    }

    /// Taps the card 001 holder row and waits for the Detail push.
    @MainActor
    private func openCard001Detail(_ app: XCUIApplication) {
        let row = app.descendants(matching: .any)[card001RowID].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Card 001 row should exist in the single fixture.")
        row.tap()

        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 10),
            "Card Detail should be pushed after tapping card 001."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail"].exists,
            "Card Detail root 'card-detail' should exist."
        )
        XCTAssertTrue(app.staticTexts["张伟"].exists, "Card name '张伟' should be visible.")
    }

    /// Opens the ••• more surface and then the Delete row, leaving the
    /// native confirmation alert on screen.
    @MainActor
    private func openDeleteConfirmation(_ app: XCUIApplication) {
        tapButton(app, identifier: moreButtonID, label: "更多操作", failureDescription: "••• more entry")

        // Native bottom action surface.
        let deleteAction = app.buttons.matching(identifier: deleteActionID).firstMatch
        if deleteAction.waitForExistence(timeout: 5) {
            // Optional more-actions evidence.
            attachScreenshot(app, name: "2026-10-04-w4i8-more-actions")
            deleteAction.tap()
        } else {
            let byLabel = app.buttons[deleteActionLabel].firstMatch
            XCTAssertTrue(byLabel.waitForExistence(timeout: 3), "The '删除' more action should appear.")
            attachScreenshot(app, name: "2026-10-04-w4i8-more-actions")
            byLabel.tap()
        }

        // The native 「提示」 confirmation precedes any deletion.
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "The delete confirmation alert should appear.")
        XCTAssertTrue(alert.staticTexts[confirmTitle].exists, "Confirmation title should be 提示.")
        XCTAssertTrue(
            alert.staticTexts[confirmMessage].exists,
            "Confirmation message must match REF-delete-01 verbatim."
        )
    }

    /// Taps a button preferring its stable accessibility identifier and
    /// falling back to its Chinese accessibility label (native bridged
    /// controls occasionally do not export the identifier).
    @MainActor
    private func tapButton(
        _ app: XCUIApplication,
        identifier: String,
        label: String,
        failureDescription: String
    ) {
        let byID = app.buttons.matching(identifier: identifier).firstMatch
        if byID.waitForExistence(timeout: 5) {
            byID.tap()
            return
        }
        let byLabel = app.buttons[label].firstMatch
        XCTAssertTrue(byLabel.waitForExistence(timeout: 3), "\(failureDescription) should be present.")
        byLabel.tap()
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - T17 confirm: delete → reload → dismiss → empty holder

    @MainActor
    func testDeleteConfirmedRemovesCardAndReturnsEmptyHolder() throws {
        let app = launchSingle()
        openCard001Detail(app)
        openDeleteConfirmation(app)

        // Required evidence: the native confirmation.
        attachScreenshot(app, name: "2026-10-04-w4i8-delete-confirmation")

        // Confirm the deletion (red 删除名片).
        let confirm = app.alerts.buttons.matching(identifier: confirmButtonID).firstMatch
        if confirm.waitForExistence(timeout: 5) {
            confirm.tap()
        } else {
            let byLabel = app.alerts.buttons[confirmButtonLabel].firstMatch
            XCTAssertTrue(byLabel.waitForExistence(timeout: 3), "The '删除名片' confirm button should appear.")
            byLabel.tap()
        }

        // Detail is dismissed AFTER the repository delete + Holder reload.
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Confirming must pop back to the Card Holder."
        )
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForNonExistence(timeout: 5),
            "The Card Detail must be gone after deletion."
        )

        // The deleted card row is absent.
        let row = app.descendants(matching: .any)[card001RowID].firstMatch
        XCTAssertFalse(row.exists, "Card 001 row must disappear after deletion.")

        // Deleting the last card returns the Holder to its empty state.
        let empty = app.descendants(matching: .any)["card-holder-empty"].firstMatch
        XCTAssertTrue(empty.waitForExistence(timeout: 5), "The empty Holder should be shown.")
        XCTAssertTrue(
            app.staticTexts["名片 (0张)"].exists,
            "The empty Holder should show the 名片 (0张) title."
        )

        // The scan entry remains available from the empty state.
        let scan = app.descendants(matching: .any)["scan-entry"].firstMatch
        XCTAssertTrue(scan.waitForExistence(timeout: 5), "The scan entry should still be available.")

        // Required evidence: holder after delete (empty).
        attachScreenshot(app, name: "2026-10-04-w4i8-holder-after-delete")
    }

    // MARK: - T17 cancel: card completely unchanged

    @MainActor
    func testDeleteCancelLeavesCardUnchanged() throws {
        let app = launchSingle()
        openCard001Detail(app)
        openDeleteConfirmation(app)

        // Cancel the confirmation (neutral 取消).
        let cancel = app.alerts.buttons.matching(identifier: cancelButtonID).firstMatch
        if cancel.waitForExistence(timeout: 5) {
            cancel.tap()
        } else {
            let byLabel = app.alerts.buttons[cancelLabel].firstMatch
            XCTAssertTrue(byLabel.waitForExistence(timeout: 3), "The '取消' button should appear.")
            byLabel.tap()
        }

        // The alert is dismissed and the Detail remains fully intact.
        XCTAssertTrue(
            app.alerts.firstMatch.waitForNonExistence(timeout: 5),
            "The confirmation must be dismissed on cancel."
        )
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 5),
            "The Card Detail must remain after cancel."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail"].exists,
            "The Card Detail root should still exist."
        )
        XCTAssertTrue(
            app.staticTexts["张伟"].waitForExistence(timeout: 5),
            "The card name should still be visible after cancel."
        )

        // Return to the Holder: card 001 is still listed (storage untouched).
        app.navigationBars["名片详情"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Back must return to the Card Holder."
        )
        let row = app.descendants(matching: .any)[card001RowID].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Card 001 must still exist after a cancelled delete.")
        XCTAssertFalse(
            app.descendants(matching: .any)["card-holder-empty"].exists,
            "The Holder must not be empty after a cancelled delete."
        )
    }
}
