//
//  ScanCameraUITests.swift
//  SimCamCardUITests
//
//  T03 Camera Permission / S02 state UI tests (Week 3 Increment 1).
//
//  Spec sources:
//   - spec/state-inventory.md S02 permissionUnknown / permissionDenied
//     / preview
//   - spec/reference-tests.md T03 Camera Permission:
//     "Allow/deny must produce defined states; denial path must not
//     crash."
//
//  These are FIXTURE-DRIVEN UI STATE tests. The app is launched with
//  the DEBUG-only `-SimCamCardCamera <mode>` argument, which injects
//  fake camera dependencies:
//
//    authorized           → preview UI state (preview container shown)
//    denied               → permissionDenied fallback, no session
//    notDeterminedGranted → fake native request resolves granted →
//                           preview (exercises the request path)
//    notDeterminedDenied  → fake native request resolves denied →
//                           permissionDenied fallback
//
//  Explicit non-claims:
//   - These do NOT verify the real native iOS permission dialog
//     (REF-permission-01-camera.png documents the system-owned dialog).
//   - These do NOT verify real live camera frames — the preview layer
//     hosts an empty fake session in the simulator.
//  Both are recorded as "NOT INDEPENDENTLY VERIFIED" in ai/changes.md.
//

import XCTest

final class ScanCameraUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @discardableResult
    @MainActor
    private func launchAndEnterScanner(cameraMode: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-SimCamCardCamera", cameraMode]
        app.launch()

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

    @MainActor
    private func closeScanner(_ app: XCUIApplication) {
        app.buttons["scan-close"].tap()
        let scannerRoot = app.descendants(matching: .any)["scan-entry-view"]
        expectation(for: NSPredicate(format: "exists == false"),
                    evaluatedWith: scannerRoot, handler: nil)
        waitForExpectations(timeout: 10)
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Closing the Scanner must return to the Card Holder."
        )
    }

    // MARK: - Authorized → preview

    @MainActor
    func testAuthorizedShowsLivePreviewContainerAndChrome() throws {
        let app = launchAndEnterScanner(cameraMode: "authorized")

        let preview = app.descendants(matching: .any)["scan-camera-preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5),
                      "Authorized fixture should show the camera preview container.")
        XCTAssertFalse(
            app.descendants(matching: .any)["scan-permission-denied"].exists,
            "Denied fallback must not appear when authorized."
        )
        // Week 2 evidence-driven overlays remain on top of the feed.
        XCTAssertTrue(app.staticTexts["请将镜头靠近名片"].exists)
        XCTAssertTrue(app.buttons["scan-capture"].exists)
        XCTAssertTrue(app.buttons["scan-photo-import"].exists)

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w3i1-scan-preview-authorized-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        closeScanner(app)
    }

    // MARK: - T04 capture (fixture-driven)

    /// Fixture-driven capture UI test: authorized → preview → tap
    /// shutter → captured presentation appears, scanner does not
    /// crash, shutter is gone, ✕ back path works.
    ///
    /// NON-CLAIM: this is NOT real camera hardware capture. The DEBUG
    /// fake session returns a fixed valid tiny PNG; this verifies the
    /// captured-state UI wiring only. Physical-device still capture is
    /// recorded as NOT INDEPENDENTLY VERIFIED in ai/changes.md.
    @MainActor
    func testCaptureShowsCapturedPhotoFixture() throws {
        let app = launchAndEnterScanner(cameraMode: "authorized")

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Preview should be running before capture."
        )

        app.buttons["scan-capture"].tap()

        // Captured presentation appears (fixture-driven).
        let captured = app.descendants(matching: .any)["scan-captured-photo"]
        XCTAssertTrue(captured.waitForExistence(timeout: 5),
                      "Tapping the shutter in preview should reach the captured state.")

        // No active shutter in the captured state; no crash.
        XCTAssertFalse(app.buttons["scan-capture"].exists,
                       "The shutter must not be offered in the captured state.")
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-entry-view"].exists,
            "Scanner must not crash after capture."
        )

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w3i2-scan-captured-photo-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        closeScanner(app)
    }

    // MARK: - Denied → stable fallback, no crash, no session

    @MainActor
    func testDeniedShowsStableFallbackWithoutSessionUI() throws {
        let app = launchAndEnterScanner(cameraMode: "denied")

        let denied = app.descendants(matching: .any)["scan-permission-denied"]
        XCTAssertTrue(denied.waitForExistence(timeout: 5),
                      "Denied fixture should show the permission-denied fallback.")
        XCTAssertFalse(
            app.descendants(matching: .any)["scan-camera-preview"].exists,
            "No preview container may exist when permission is denied."
        )
        // Capture UI must not be offered without camera access.
        XCTAssertFalse(app.buttons["scan-capture"].exists)
        XCTAssertFalse(app.buttons["scan-photo-import"].exists)

        // Denial path must not crash; the ✕ back path still works.
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w3i1-scan-permission-denied-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        closeScanner(app)
    }

    // MARK: - notDetermined → granted (request path)

    @MainActor
    func testNotDeterminedGrantedResolvesToPreview() throws {
        let app = launchAndEnterScanner(cameraMode: "notDeterminedGranted")

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Granting the (fixture) permission request should enter preview."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["scan-permission-denied"].exists,
            "Denied fallback must not appear after grant."
        )
        closeScanner(app)
    }

    // MARK: - notDetermined → denied (request path)

    @MainActor
    func testNotDeterminedDeniedResolvesToFallback() throws {
        let app = launchAndEnterScanner(cameraMode: "notDeterminedDenied")

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-permission-denied"].waitForExistence(timeout: 5),
            "Denying the (fixture) permission request should show the fallback."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["scan-camera-preview"].exists,
            "Preview must not appear after denial."
        )
        closeScanner(app)
    }
}
