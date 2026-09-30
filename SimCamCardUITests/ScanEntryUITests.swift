//
//  ScanEntryUITests.swift
//  SimCamCardUITests
//
//  T02 — Scan Entry / Scanner UI shell UI tests (XCTest).
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder (exit: Scanner),
//     P02 Scanner (exit: Back)
//   - spec/state-inventory.md S02 Camera / Scanner (this increment
//     covers only the static shell presentation + the back path)
//   - spec/reference-tests.md T02 Enter Scanner:
//     "Scan entry opens scanner/camera UI."
//   - Evidence: evidence/screenshots/REF-scanner-01-initial.png
//
//  Real navigation flow under test:
//   launch (empty holder) → tap "scan-entry" → Scanner shell pushes →
//   verify evidence-supported static controls → close back to Holder.
//
//  Scope:
//   - PASS claimed for scan-entry navigation + static scanner-shell
//     presentation + close/back navigation only.
//   - NOT verified / NOT implemented: live camera preview, camera
//     permission dialog, shutter capture workflow (T04), photo import /
//     picker (T05), mode switching, more menu, batch review.
//   - The visual shutter / 相册 controls are tapped in Test 1 only to
//     prove they have NO out-of-scope side effects (remain on Scanner).
//
//  No simulator permission dependency: the shell never queries camera
//  authorization, so these tests run without granting any permission.
//

import XCTest

final class ScanEntryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app with its default empty repository and opens the
    /// Scanner shell via the holder scan entry.
    @discardableResult
    private func launchAndEnterScanner() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Card Holder should be visible after launch."
        )

        let scanEntry = app.buttons["scan-entry"]
        XCTAssertTrue(
            scanEntry.waitForExistence(timeout: 10),
            "Scan entry 'scan-entry' should exist on the Card Holder."
        )
        scanEntry.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-entry-view"].waitForExistence(timeout: 10),
            "Scanner root 'scan-entry-view' should appear after tapping scan entry."
        )
        return app
    }

    @MainActor
    func testEnterScannerShowsStaticShell() throws {
        let app = launchAndEnterScanner()

        // Evidence-supported static elements from REF-scanner-01:
        // guidance tip, static recognition-mode selector, static capture
        // mode tabs, photo entry and shutter.
        XCTAssertTrue(
            app.staticTexts["请将镜头靠近名片"].exists,
            "The Reference guidance tip should be shown inside the viewport."
        )
        XCTAssertTrue(
            app.staticTexts["基础识别"].exists,
            "The static recognition-mode selector should show 基础识别."
        )
        XCTAssertTrue(
            app.staticTexts["单张拍摄"].exists,
            "The static capture-mode tabs should show the selected 单张拍摄 tab."
        )
        XCTAssertTrue(
            app.buttons["scan-photo-import"].waitForExistence(timeout: 5),
            "The visual photo-import shell control should exist."
        )
        XCTAssertTrue(
            app.buttons["scan-capture"].exists,
            "The visual shutter shell control should exist."
        )
        XCTAssertTrue(
            app.buttons["scan-close"].exists,
            "The close control should exist for the back path."
        )

        // No developer placeholder text leaks into the scanner UI.
        XCTAssertFalse(app.staticTexts["Coming soon"].exists)
        XCTAssertFalse(app.staticTexts["Not implemented"].exists)

        // Visual controls have no out-of-scope behavior: tapping them
        // must keep the user on the Scanner shell (no navigation, no
        // system picker, no crash).
        app.buttons["scan-capture"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-entry-view"].exists,
            "Tapping the shell shutter must not leave the Scanner page."
        )
        app.buttons["scan-photo-import"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-entry-view"].exists,
            "Tapping the shell photo entry must not present a picker or leave the page."
        )

        // Validation evidence (separate from frozen REF-* screenshots).
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "increment6-scan-entry"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCloseReturnsToCardHolderWithStateUnchanged() throws {
        let app = launchAndEnterScanner()

        // Close (✕) uses the system NavigationStack pop.
        app.buttons["scan-close"].tap()

        let scannerRoot = app.descendants(matching: .any)["scan-entry-view"]
        let disappeared = NSPredicate(format: "exists == false")
        expectation(for: disappeared, evaluatedWith: scannerRoot, handler: nil)
        waitForExpectations(timeout: 10)

        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Closing the Scanner should return to the Card Holder."
        )

        // Card state is unchanged by the round trip: default launch has
        // zero card rows. Uses the same BEGINSWITH identifier contract
        // as the T01 empty-holder test.
        let cardRowCount = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "card-row-"))
            .count
        XCTAssertEqual(
            cardRowCount,
            0,
            "Opening/closing the Scanner shell must not create any cards."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-holder-empty"].exists,
            "The empty Card Holder state should still be present after returning."
        )
    }
}
