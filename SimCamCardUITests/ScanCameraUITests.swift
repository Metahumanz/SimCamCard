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
    private func launchAndEnterScanner(
        cameraMode: String,
        photoImportMode: String? = nil,
        detectionMode: String? = nil,
        cropMode: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var args = ["-SimCamCardCamera", cameraMode]
        if let photoImportMode {
            args += ["-SimCamCardPhotoImport", photoImportMode]
        }
        if let detectionMode {
            args += ["-SimCamCardDetection", detectionMode]
        }
        if let cropMode {
            args += ["-SimCamCardCrop", cropMode]
        }
        app.launchArguments = args
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
    /// shutter → the P04 crop page appears (Week 3 Increment 5: capture
    /// now flows into the shared still pipeline), the scanner does not
    /// crash, the shutter is gone, and retake returns to preview.
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

        // Capture now enters P04 crop preparation/adjustment.
        let cropView = app.descendants(matching: .any)["scan-crop-view"]
        XCTAssertTrue(cropView.waitForExistence(timeout: 5),
                      "Tapping the shutter should enter the crop page.")
        XCTAssertTrue(app.buttons["scan-crop-confirm"].waitForExistence(timeout: 3),
                      "The crop page offers the confirm action.")

        // No active shutter while the crop page owns the screen; no crash.
        XCTAssertFalse(app.buttons["scan-capture"].exists,
                       "The shutter must not be offered during crop adjustment.")
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-entry-view"].exists,
            "Scanner must not crash after capture."
        )

        // Retake returns to the live preview.
        app.buttons["scan-crop-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Retake should return to the camera preview."
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

    // MARK: - T05 photo import: fixture selection success

    /// Fixture-driven import UI test: authorized → tap 相册 → the
    /// DEBUG photo-import fixture simulates a successful selection →
    /// the imported image presentation appears, the shutter is gone,
    /// and the scanner does not crash.
    ///
    /// NON-CLAIM: this is NOT real system PhotosPicker selection. The
    /// DEBUG fixture bypasses the native picker entirely and feeds
    /// valid image bytes directly to the ViewModel. Native picker
    /// runtime verification is recorded as NOT INDEPENDENTLY VERIFIED
    /// in ai/changes.md.
    @MainActor
    func testPhotoImportFixtureShowsImportedPhoto() throws {
        let app = launchAndEnterScanner(cameraMode: "authorized", photoImportMode: "imported")

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Preview should be running before import."
        )

        app.buttons["scan-photo-import"].tap()

        // The import now enters the shared still pipeline → P04.
        let cropView = app.descendants(matching: .any)["scan-crop-view"]
        XCTAssertTrue(cropView.waitForExistence(timeout: 5),
                      "Tapping 相册 with the imported fixture should enter the crop page.")

        // No active shutter while the crop page owns the screen; no crash.
        XCTAssertFalse(app.buttons["scan-capture"].exists,
                       "The shutter must not be offered during crop adjustment.")
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-entry-view"].exists,
            "Scanner must not crash after import."
        )

        // Retake returns to the live preview; the user can tap 相册 again.
        app.buttons["scan-crop-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Retake should return to the scanner preview."
        )
        XCTAssertTrue(app.buttons["scan-photo-import"].exists,
                      "The photo-library entry must be available again after retake.")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w3i3-scan-imported-photo-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        closeScanner(app)
    }

    // MARK: - T05 photo import: fixture cancel returns to preview

    /// Fixture-driven cancel UI test: authorized → tap 相册 → the DEBUG
    /// fixture simulates a picker cancel → the scanner returns to the
    /// preview state with the shutter available again.
    @MainActor
    func testPhotoImportCancelReturnsToPreview() throws {
        let app = launchAndEnterScanner(cameraMode: "authorized", photoImportMode: "cancel")

        app.buttons["scan-photo-import"].tap()

        // After cancel, the preview returns and the shutter is offered
        // again. No imported image, no crash.
        let preview = app.descendants(matching: .any)["scan-camera-preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5),
                      "Cancelling the import should return to the camera preview.")
        XCTAssertTrue(app.buttons["scan-capture"].waitForExistence(timeout: 2),
                      "The shutter should be available again after cancel.")
        XCTAssertFalse(
            app.descendants(matching: .any)["scan-imported-photo"].exists,
            "Cancel must not show an imported photo."
        )

        closeScanner(app)
    }

    // MARK: - T06 detection: card detected fixture

    /// Fixture-driven overlay regression: authorized preview + detected
    /// fixture → cyan quadrilateral overlay appears, guidance tip
    /// switches to "发现名片，点击拍摄", and the shutter remains.
    ///
    /// NON-CLAIM: this is NOT real Vision detection. The DEBUG fixture
    /// yields a fixed CardRegion directly; real camera live detection is
    /// recorded as NOT INDEPENDENTLY VERIFIED in ai/changes.md.
    @MainActor
    func testDetectionFixtureShowsOverlayAndDetectedTip() throws {
        let app = launchAndEnterScanner(
            cameraMode: "authorized",
            detectionMode: "detected"
        )

        let preview = app.descendants(matching: .any)["scan-camera-preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5),
                      "Preview should be running.")

        let overlay = app.descendants(matching: .any)["scan-card-detected-overlay"]
        XCTAssertTrue(overlay.waitForExistence(timeout: 5),
                      "Detected fixture should show the card-detected overlay.")

        // The static white aiming guide is replaced by the detected overlay.
        XCTAssertFalse(
            app.staticTexts["请将镜头靠近名片"].exists,
            "Static guidance tip must be replaced when card detected."
        )
        XCTAssertTrue(
            app.staticTexts["发现名片，点击拍摄"].exists,
            "Detected guidance tip must be shown."
        )

        // Shutter remains available so the user can capture.
        XCTAssertTrue(app.buttons["scan-capture"].exists,
                      "The shutter must remain available when a card is detected.")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w3i4-scan-card-detected-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        closeScanner(app)
    }

    // MARK: - T06 detection: card not detected fixture

    /// Fixture-driven overlay absence regression: authorized preview +
    /// notdetected fixture → overlay is absent, static guide + tip remain,
    /// and the scanner stays usable.
    @MainActor
    func testNotDetectedFixtureHidesOverlayAndShowsGuidance() throws {
        let app = launchAndEnterScanner(
            cameraMode: "authorized",
            detectionMode: "notdetected"
        )

        let preview = app.descendants(matching: .any)["scan-camera-preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5),
                      "Preview should be running.")

        XCTAssertFalse(
            app.descendants(matching: .any)["scan-card-detected-overlay"].exists,
            "Not-detected fixture must not show the detected overlay."
        )

        XCTAssertTrue(
            app.staticTexts["请将镜头靠近名片"].exists,
            "Static guidance tip must remain when no card is detected."
        )
        XCTAssertFalse(
            app.staticTexts["发现名片，点击拍摄"].exists,
            "Detected guidance tip must not appear without detection."
        )

        XCTAssertTrue(app.buttons["scan-capture"].exists,
                      "The shutter must remain available.")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w3i4-scan-card-not-detected-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        closeScanner(app)
    }

    // MARK: - P04 crop: auto detected fixture

    /// Fixture-driven P04 regression: authorized → shutter → crop page
    /// with boundary, four handles, confirm and retake controls.
    ///
    /// NON-CLAIM: the initial region comes from the DEBUG fixture, not
    /// real still-image Vision; geometry mutation is covered by unit
    /// tests, and real dataset Detection→Crop by processor smoke tests.
    @MainActor
    private func enterCropPage(cropMode: String) -> XCUIApplication {
        let app = launchAndEnterScanner(cameraMode: "authorized", cropMode: cropMode)
        app.buttons["scan-capture"].tap()

        let cropView = app.descendants(matching: .any)["scan-crop-view"]
        XCTAssertTrue(cropView.waitForExistence(timeout: 5),
                      "Shutter should enter the crop page.")
        return app
    }

    @MainActor
    func testCropAutoDetectedShowsBoundaryHandlesAndControls() throws {
        let app = enterCropPage(cropMode: "auto")

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-boundary"].waitForExistence(timeout: 5),
            "Auto-detected crop page must show the boundary quadrilateral."
        )
        for handleId in [
            "scan-crop-handle-top-left",
            "scan-crop-handle-top-right",
            "scan-crop-handle-bottom-right",
            "scan-crop-handle-bottom-left",
        ] {
            XCTAssertTrue(app.descendants(matching: .any)[handleId].exists,
                          "Crop page must show handle \(handleId).")
        }
        XCTAssertTrue(app.buttons["scan-crop-confirm"].exists)
        XCTAssertTrue(app.buttons["scan-crop-retake"].exists)

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w3i5-crop-auto-detected-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["scan-crop-retake"].tap()
        closeScanner(app)
    }

    // MARK: - P04 crop: manual adjust fixture

    /// Deterministic manual-adjust regression: starting directly in
    /// manual-adjust state, drag one corner inward; the page stays
    /// stable with boundary and confirm controls usable.
    @MainActor
    func testCropManualDragKeepsPageStable() throws {
        let app = enterCropPage(cropMode: "manual")

        let handle = app.descendants(matching: .any)["scan-crop-handle-top-left"]
        XCTAssertTrue(handle.waitForExistence(timeout: 5),
                      "Manual-adjust page must show the corner handle.")

        // Small inward drag; the candidate stays a valid convex region.
        let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: 30, dy: 24))
        start.press(forDuration: 0.1, thenDragTo: end)

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-boundary"].exists,
            "Boundary must remain after the drag."
        )
        XCTAssertTrue(app.buttons["scan-crop-confirm"].isEnabled,
                      "Confirm must remain usable after the drag.")
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-view"].exists,
            "Page must stay stable (no crash, no navigation) after the drag."
        )

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w3i5-crop-manual-adjust-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["scan-crop-retake"].tap()
        closeScanner(app)
    }

    // MARK: - P04 crop: confirm fixture

    /// Confirm runs the REAL CardCropProcessor on the deterministic
    /// fixture image: tap 完成 → the perspective-corrected image is
    /// presented, handles/boundary are gone, and no OCR/recognition UI
    /// is faked.
    @MainActor
    func testCropConfirmShowsCorrectedImageWithoutHandles() throws {
        let app = enterCropPage(cropMode: "auto")

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-boundary"].waitForExistence(timeout: 5),
            "Crop page should be ready before confirm."
        )

        app.buttons["scan-crop-confirm"].tap()

        let confirmed = app.descendants(matching: .any)["scan-crop-confirmed-image"]
        XCTAssertTrue(confirmed.waitForExistence(timeout: 10),
                      "Confirm should present the perspective-corrected image.")

        for handleId in [
            "scan-crop-handle-top-left",
            "scan-crop-handle-top-right",
            "scan-crop-handle-bottom-right",
            "scan-crop-handle-bottom-left",
        ] {
            XCTAssertFalse(app.descendants(matching: .any)[handleId].exists,
                           "Handles must be absent after confirm (\(handleId)).")
        }
        XCTAssertFalse(
            app.descendants(matching: .any)["scan-crop-boundary"].exists,
            "Editing boundary must be absent after confirm."
        )

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w3i5-crop-confirmed-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
