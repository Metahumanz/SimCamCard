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
//   - PASS claimed for scan-entry navigation + scanner chrome
//     presentation (now over the fixture-driven preview state) +
//     close/back navigation.
//   - NOT verified / NOT implemented: real camera hardware, the native
//     permission dialog, shutter capture workflow (T04), photo import /
//     picker (T05), mode switching, more menu, batch review.
//   - The visual shutter / 相册 controls are tapped in Test 1 only to
//     prove they have NO out-of-scope side effects (remain on Scanner).
//
//  Week 3 Increment 1: these UI tests launch with the DEBUG-only
//  `-SimCamCardCamera authorized` fixture so the Scanner enters its
//  preview UI state deterministically WITHOUT triggering the native
//  camera permission dialog (which cannot be automated in the
//  simulator). This is fixture-driven UI state verification, NOT native
//  permission or real live-frame verification.
//

import XCTest

final class ScanEntryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app with its default empty repository and the
    /// DEBUG authorized-camera fixture, then opens the Scanner via the
    /// holder scan entry.
    @discardableResult
    @MainActor
    private func launchAndEnterScanner() -> XCUIApplication {
        let app = UITestAppFactory.launchEphemeral(
            arguments: ["-SimCamCardCamera", "authorized"]
        )

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

        // Authorized fixture drives the preview UI state (fixture-driven
        // UI verification — the preview layer hosts an empty fake
        // session, NOT a real camera feed).
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "The camera preview container should exist in the authorized fixture state."
        )

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

        // Shutter is a real T04 capture action (Week 3 Increment 2):
        // tapping it in preview captures and reaches the captured state.
        // (Full capture-flow coverage lives in ScanCameraUITests.
        // T05 photo-import coverage lives in ScanCameraUITests with the
        // `-SimCamCardPhotoImport` fixture.)
        app.buttons["scan-capture"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-captured-photo"].waitForExistence(timeout: 5),
            "Tapping the shutter in preview should reach the captured state."
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
