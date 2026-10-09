//
//  ExceptionHandlingUITests.swift
//  SimCamCardUITests
//
//  Week 4 Increment 12 — T20 high-value composite exception flows.
//
//  Spec sources:
//   - plan W4I12 §27 composites B / C plus the §10 failure-Cancel exit
//   - dataset/exception-samples/t20-negative-001-expected.json
//   - spec/state-inventory.md S05 nonCardEmptyResult / failed
//   - evidence REF-exception-01-minimal-card-empty-fields.png
//     / REF-exception-02-non-card-empty-result.png
//
//  Audit note (W4I12 matrix): composites A (camera denied → close →
//  Holder) and D failure → 重拍 → clean scanner already exist in
//  ScanCameraUITests (testDeniedShowsStableFallbackWithoutSessionUI +
//  testNotDeterminedDeniedResolvesToFallback, and
//  testOCRFailureShowsStableRecoveryAndRetake) and are NOT duplicated
//  here. This file covers only genuinely new proof:
//
//   B. non-card empty result: 保存 disabled, tap is a no-op, no card is
//      materialized; 重拍 then ✕ returns to the unchanged empty Holder.
//   C. card-004 minimal result through the full scan chain: only name +
//      one mobile surface; no fabricated company/title/email/website;
//      the minimal card remains saveable (it has real fields).
//   E06. OCR failure → the new direct 取消 exit leaves the whole scan
//      flow straight back to the Holder.
//
//  Every case is FIXTURE-DRIVEN (DEBUG-only launch arguments), NOT real
//  camera hardware or real Vision OCR.
//

import XCTest

final class ExceptionHandlingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    @discardableResult
    @MainActor
    private func launchAndEnterScanner(ocrMode: String) -> XCUIApplication {
        let app = UITestAppFactory.launchEphemeral(arguments: [
            "-SimCamCardCamera", "authorized",
            "-SimCamCardCrop", "auto",
            "-SimCamCardOCR", ocrMode
        ])
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Card Holder should be visible after launch."
        )
        app.buttons["scan-entry"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-entry-view"].waitForExistence(timeout: 10),
            "Scanner root should appear."
        )
        return app
    }

    /// Shutter → crop page → 完成 → waits for the P05 form / failure.
    @MainActor
    private func captureConfirmCrop(_ app: XCUIApplication) {
        app.buttons["scan-capture"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-view"].waitForExistence(timeout: 5),
            "Shutter should enter the crop page."
        )
        app.buttons["scan-crop-confirm"].tap()
    }

    // MARK: - B. Non-card empty result cannot be saved; cancel returns

    /// Composite B (plan §27): a valid non-card image yields zero
    /// recognized fields → the P05 edit-card form opens EMPTY (exactly
    /// per t20-negative-001-expected.json), with no failure dialog.
    /// 保存 stays visible (REF-exception-02 shows it) but is DISABLED
    /// and tapping it must not materialize a blank card. The user exits
    /// via 重拍 → Scanner ✕ and finds the Holder unchanged (empty).
    @MainActor
    func testCompositeBNonCardEmptyCannotSaveThenCancel() throws {
        let app = launchAndEnterScanner(ocrMode: "empty")
        captureConfirmCrop(app)

        // Empty form, NOT a failure dialog.
        let form = app.descendants(matching: .any)["scan-recognition-form"]
        XCTAssertTrue(form.waitForExistence(timeout: 10),
                      "Non-card image must enter the edit-card form.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-recognition-empty"].exists,
                      "State marker must be nonCardEmptyResult.")
        XCTAssertFalse(app.descendants(matching: .any)["scan-recognition-failed"].exists,
                       "Non-card empty result must not show a failure surface.")

        // 保存 present but disabled → no blank card can be saved.
        let save = app.buttons["scan-recognition-save"]
        XCTAssertTrue(save.waitForExistence(timeout: 3), "保存 stays visible per REF.")
        XCTAssertFalse(save.isEnabled, "保存 must be disabled with zero recognized fields.")
        save.tap()
        XCTAssertFalse(app.descendants(matching: .any)["scan-save-success"].exists,
                       "Tapping disabled 保存 must not open the save result.")

        // No fabricated structured values.
        XCTAssertFalse(app.staticTexts["未命名"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-website"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-mobile-0"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-email-0"].exists)

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w4i12-non-card-empty-result"
        attachment.lifetime = .keepAlways
        add(attachment)

        // 重拍 → clean scanner, then ✕ → Holder.
        app.buttons["scan-recognition-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "重拍 must return to the scanner preview."
        )
        app.buttons["scan-close"].tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Closing the scanner must return to the Card Holder."
        )

        // No blank card was persisted: the ephemeral Holder is still empty.
        XCTAssertTrue(
            app.descendants(matching: .any)["card-holder-empty"].waitForExistence(timeout: 5),
            "A non-card result must never materialize a saved card."
        )
        XCTAssertEqual(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH %@", "card-row-")).count,
            0,
            "No card rows may exist after the empty-result cancel."
        )
    }

    // MARK: - C. Minimal card: only real fields, nothing fabricated

    /// Composite C (plan §27): card-004-style result through the full
    /// fixture chain settles in missingFields with exactly name + one
    /// mobile (+86 138… auto-classified mobile). No company / job title
    /// value, no email, no website row, no second phone; the minimal
    /// card still offers enabled 保存 (real fields are present).
    @MainActor
    func testCompositeCMinimalCardShowsOnlyExistingFields() throws {
        let app = launchAndEnterScanner(ocrMode: "minimal")
        captureConfirmCrop(app)

        let form = app.descendants(matching: .any)["scan-recognition-form"]
        XCTAssertTrue(form.waitForExistence(timeout: 10),
                      "Minimal fixture must enter the P05 form.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-recognition-missing"].exists,
                      "Name+mobile only (other canonical fields absent) → missingFields.")
        XCTAssertFalse(app.descendants(matching: .any)["scan-recognition-empty"].exists,
                       "A card with real fields must never be classified nonCardEmpty.")

        // Real fields surface.
        let name = app.descendants(matching: .any)["scan-field-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "Name row must exist.")
        XCTAssertTrue(name.staticTexts["张伟"].exists, "Name must be 张伟.")

        let mobile = app.descendants(matching: .any)["scan-field-mobile-0"]
        XCTAssertTrue(mobile.exists, "Exactly one mobile row must exist.")
        XCTAssertTrue(mobile.staticTexts["+86 138 0013 8000"].exists,
                      "Bare +86 international mobile must keep its digits.")

        // Nothing fabricated: no other phone kinds, no email, no website.
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-office-0"].exists,
                       "No office phone may be fabricated.")
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-fax-0"].exists,
                       "No fax may be fabricated.")
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-email-0"].exists,
                       "No email may be fabricated.")
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-website"].exists,
                       "No website row may exist on the minimal card.")
        let company = app.descendants(matching: .any)["scan-field-company"]
        XCTAssertTrue(company.exists, "Company structural row stays present (empty value).")
        XCTAssertFalse(company.staticTexts["未识别"].exists)
        XCTAssertFalse(app.staticTexts["N/A"].exists)
        XCTAssertFalse(app.staticTexts["Unknown"].exists)

        // Real fields → saving remains allowed.
        let save = app.buttons["scan-recognition-save"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        XCTAssertTrue(save.isEnabled, "A minimal card with real fields must be saveable.")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w4i12-minimal-card"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Discard via 重拍 (no save in this test) and leave cleanly.
        app.buttons["scan-recognition-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "重拍 must return to the scanner preview."
        )
        app.buttons["scan-close"].tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Closing the scanner must return to the Card Holder."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-holder-empty"].waitForExistence(timeout: 5),
            "Nothing should have been saved after discarding the minimal flow."
        )
    }

    // MARK: - E06. OCR failure direct Cancel returns to the Holder

    /// §10: an OCR request failure lands on the failure fallback with
    /// BOTH exits. 重拍 is covered in ScanCameraUITests; this case
    /// verifies the direct 取消 exit: the whole scanner is dismissed to
    /// the Holder, with no stale recognition screen and no save.
    @MainActor
    func testOCRFailureCancelReturnsDirectlyToHolder() throws {
        let app = launchAndEnterScanner(ocrMode: "failure")
        captureConfirmCrop(app)

        let failed = app.descendants(matching: .any)["scan-recognition-failed"]
        XCTAssertTrue(failed.waitForExistence(timeout: 10),
                      "OCR failure must present the failure fallback.")
        let cancel = app.buttons["scan-recognition-cancel"]
        let retake = app.buttons["scan-recognition-retake"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 3), "Failure fallback must offer 取消.")
        XCTAssertTrue(retake.exists, "Failure fallback must still offer 重拍.")
        XCTAssertEqual(app.buttons.matching(identifier: "scan-recognition-save").count, 0,
                       "No Save action may exist on the failure fallback.")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w4i12-recognition-failure"
        attachment.lifetime = .keepAlways
        add(attachment)

        cancel.tap()

        // Wait for the scanner root to be removed (direct dismiss).
        let scannerRoot = app.descendants(matching: .any)["scan-entry-view"]
        var dismissed = false
        for _ in 0..<20 {
            if !scannerRoot.exists { dismissed = true; break }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }
        XCTAssertTrue(dismissed, "取消 must dismiss the whole scanner flow.")
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "取消 on failure must return to the Card Holder."
        )
        XCTAssertFalse(app.descendants(matching: .any)["scan-recognition-failed"].exists,
                       "No stale failure surface may remain after cancel.")
    }
}
