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
        cropMode: String? = nil,
        ocrMode: String? = nil
    ) -> XCUIApplication {
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
        if let ocrMode {
            args += ["-SimCamCardOCR", ocrMode]
        }
        let app = UITestAppFactory.launchEphemeral(arguments: args)

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
    private func enterCropPage(cropMode: String, ocrMode: String? = nil) -> XCUIApplication {
        let app = launchAndEnterScanner(
            cameraMode: "authorized", cropMode: cropMode, ocrMode: ocrMode
        )
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
    /// fixture image (Week 3 Increment 5). Increment 6 extends the
    /// flow: tap 完成 → the perspective-corrected image becomes the
    /// substrate of the T07 raw recognition screen that automatically
    /// follows; the editing boundary/handles are gone.
    @MainActor
    func testCropConfirmFlowsIntoStructuredRecognitionWithoutHandles() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "success")

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-boundary"].waitForExistence(timeout: 5),
            "Crop page should be ready before confirm."
        )

        app.buttons["scan-crop-confirm"].tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-recognition-form"].waitForExistence(timeout: 10),
            "Confirm must auto-flow into the P05 structured recognition form."
        )

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

        app.buttons["scan-recognition-retake"].tap()
        closeScanner(app)
    }

    // MARK: - P05 structured recognition: success fixture

    /// Fixture-driven T08 success regression: crop 完成 → the P05
    /// structured form presents the extracted fields (name / company /
    /// job title / mobile / office / email / website / address) in a
    /// read-only layout. No Save action exists.
    ///
    /// NON-CLAIM: this is NOT real Vision OCR. The DEBUG fixture
    /// returns fixed lines; real recognition is covered by
    /// CardOCRProcessorTests and the OCR dataset smoke tests.
    @MainActor
    func testStructuredRecognitionSuccessShowsP05Fields() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "success")

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-boundary"].waitForExistence(timeout: 5),
            "Crop page should be ready before confirm."
        )
        app.buttons["scan-crop-confirm"].tap()

        let form = app.descendants(matching: .any)["scan-recognition-form"]
        XCTAssertTrue(form.waitForExistence(timeout: 5),
                      "Confirm must enter the P05 structured recognition form.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-recognition-structured"].exists,
                      "State marker must be structuredResultAvailable.")

        // Field values must be present and correct.
        let name = app.descendants(matching: .any)["scan-field-name"]
        XCTAssertTrue(name.exists, "Name field must exist.")
        XCTAssertTrue(name.staticTexts["张伟"].exists, "Name must be 张伟.")

        let company = app.descendants(matching: .any)["scan-field-company"]
        XCTAssertTrue(company.exists, "Company field must exist.")
        XCTAssertTrue(company.staticTexts["上海智云科技有限公司"].exists,
                      "Company must contain 智云.")

        let title = app.descendants(matching: .any)["scan-field-job-title"]
        XCTAssertTrue(title.exists, "Job title field must exist.")
        XCTAssertTrue(title.staticTexts["产品总监 | Product Director"].exists,
                      "Job title must contain 产品总监.")

        let mobile = app.descendants(matching: .any)["scan-field-mobile-0"]
        XCTAssertTrue(mobile.exists, "Mobile field must exist.")
        XCTAssertTrue(mobile.staticTexts["+86 138 0013 8000"].exists,
                      "Mobile must contain 13800138000.")

        let office = app.descendants(matching: .any)["scan-field-office-0"]
        XCTAssertTrue(office.exists, "Office field must exist.")
        XCTAssertTrue(office.staticTexts["+86 21 5555 1234"].exists,
                      "Office must contain 2155551234.")

        let email = app.descendants(matching: .any)["scan-field-email-0"]
        XCTAssertTrue(email.exists, "Email field must exist.")
        XCTAssertTrue(email.staticTexts["wei.zhang@zhiyuntech.com"].exists,
                      "Email must contain wei.zhang.")

        let website = app.descendants(matching: .any)["scan-field-website"]
        XCTAssertTrue(website.exists, "Website field must exist.")
        XCTAssertTrue(website.staticTexts["www.zhiyuntech.com"].exists,
                      "Website must contain zhiyuntech.")

        let address = app.descendants(matching: .any)["scan-field-address"]
        XCTAssertTrue(address.exists, "Address field must exist.")
        XCTAssertTrue(address.staticTexts["上海市浦东新区世纪大道100号 200120"].exists,
                      "Address must be present.")

        // No raw-text block; since the T12 calibration the read-only
        // form offers BOTH 编辑 and direct 保存.
        XCTAssertFalse(app.descendants(matching: .any)["scan-recognition-raw-text"].exists,
                       "P05 must not present the old raw-text block.")
        XCTAssertTrue(app.buttons["scan-recognition-save"].exists,
                      "The read-only P05 form must offer direct 保存.")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w4i2-structured-success-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["scan-recognition-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Retake must return to the scanner preview."
        )
        closeScanner(app)
    }

    // MARK: - P05 structured recognition: empty fixture

    /// Fixture-driven S05 empty-result regression: zero recognized
    /// lines land on a distinct nonCardEmptyResult P05 form — not a
    /// failure, with no fabricated contact fields and a 重拍 recovery
    /// path. This is the frozen S05 nonCardEmptyResult state.
    ///
    /// Structural scope: the fixed scalar rows (姓名/公司/职位/公司地址)
    /// remain present with empty values; data-driven rows are absent
    /// (website per card-b evidence; phones/emails per actual elements).
    /// This does NOT claim T20 full reference fidelity — the empty-card
    /// visual behavior beyond this conservative structure has no
    /// dedicated Reference evidence yet.
    @MainActor
    func testStructuredEmptyFixtureShowsEmptyP05WithoutFailure() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "empty")

        app.buttons["scan-crop-confirm"].tap()

        let form = app.descendants(matching: .any)["scan-recognition-form"]
        XCTAssertTrue(form.waitForExistence(timeout: 5),
                      "Zero-text OCR must present the P05 form.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-recognition-empty"].exists,
                      "State marker must be nonCardEmptyResult.")
        XCTAssertFalse(app.descendants(matching: .any)["scan-recognition-failed"].exists,
                       "Empty is a valid result, not a failure.")
        XCTAssertFalse(app.descendants(matching: .any)["scan-recognition-raw-text"].exists,
                       "P05 must not present the old raw-text block.")
        // Saving an empty result is a legitimate settled-state save; the
        // no-fabrication claim is about field VALUES (checked below).
        XCTAssertTrue(app.buttons["scan-recognition-save"].exists,
                      "The empty-result P05 form still offers 保存.")

        // Fixed structural scalar rows stay present with empty values.
        let name = app.descendants(matching: .any)["scan-field-name"]
        XCTAssertTrue(name.exists, "Name structural row must exist.")
        XCTAssertTrue(name.staticTexts["姓名"].exists, "Name row shows its label.")
        // The only text inside the empty row is its label (an empty value
        // Text carries no non-empty content).
        let unexpectedNameValues = name.staticTexts.matching(
            NSPredicate(format: "label != '姓名' AND label != ''")
        )
        XCTAssertEqual(unexpectedNameValues.count, 0,
                       "Empty name row must not carry a fabricated value.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-company"].exists,
                      "Company structural row must exist.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-job-title"].exists,
                      "Job-title structural row must exist.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-address"].exists,
                      "Address structural row must exist.")

        // Data-driven rows: nothing recognized → absent.
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-website"].exists,
                       "No website row may exist for a zero-text result.")
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-mobile-0"].exists,
                       "No phone rows may exist for a zero-text result.")
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-email-0"].exists,
                       "No email rows may exist for a zero-text result.")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w4i2-structured-empty-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["scan-recognition-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Retake must return to the scanner preview."
        )
        closeScanner(app)
    }

    // MARK: - P05 structured recognition: missing field fixture

    /// Fixture-driven T09 missing-field regression: card-002 style
    /// (no website) lands on missingFields; the missing 首页 row is
    /// OMITTED ENTIRELY (Reference REF-recognition-03/04 card-b) —
    /// no empty row, no "N/A"/"未识别", no website fabricated from
    /// the email domain.
    @MainActor
    func testStructuredMissingFieldFixtureOmitsWebsiteRow() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "missing")

        app.buttons["scan-crop-confirm"].tap()

        let form = app.descendants(matching: .any)["scan-recognition-form"]
        XCTAssertTrue(form.waitForExistence(timeout: 5),
                      "Missing-field fixture must present the P05 form.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-recognition-missing"].exists,
                      "State marker must be missingFields.")

        // The missing website row must not exist at all — neither an
        // empty labeled row nor a fabricated value.
        XCTAssertFalse(app.descendants(matching: .any)["scan-field-website"].exists,
                       "Missing website must omit the 首页 row entirely.")
        XCTAssertFalse(app.staticTexts["www.zhiyuntech.com"].exists,
                       "Website must not be fabricated from the email domain.")
        XCTAssertFalse(app.staticTexts["N/A"].exists)
        XCTAssertFalse(app.staticTexts["未识别"].exists)

        // Recognized fields are still displayed.
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-name"].exists,
                      "Name field must exist.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-company"].exists,
                      "Company field must exist.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-email-0"].exists,
                      "Email field must exist.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-address"].exists,
                      "Address field must exist.")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w4i2-structured-missing-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["scan-recognition-retake"].tap()
        closeScanner(app)
    }

    // MARK: - P05 structured recognition: multiple phone fixture

    /// Fixture-driven T10 multiple-phone regression: card-003 style
    /// (mobile + office + fax) lands on multiplePhoneFields; all three
    /// phone kinds are displayed separately.
    @MainActor
    func testStructuredMultiplePhoneFixtureShowsMobileOfficeFax() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "multiple")

        app.buttons["scan-crop-confirm"].tap()

        let form = app.descendants(matching: .any)["scan-recognition-form"]
        XCTAssertTrue(form.waitForExistence(timeout: 5),
                      "Multiple-phone fixture must present the P05 form.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-recognition-multiple"].exists,
                      "State marker must be multiplePhoneFields.")

        let mobile = app.descendants(matching: .any)["scan-field-mobile-0"]
        XCTAssertTrue(mobile.exists, "Mobile field must exist.")
        XCTAssertTrue(mobile.staticTexts["+86 136 8888 1024"].exists)

        let office = app.descendants(matching: .any)["scan-field-office-0"]
        XCTAssertTrue(office.exists, "Office field must exist.")
        XCTAssertTrue(office.staticTexts["+86 21 5666 7788"].exists)

        let fax = app.descendants(matching: .any)["scan-field-fax-0"]
        XCTAssertTrue(fax.exists, "Fax field must exist.")
        XCTAssertTrue(fax.staticTexts["+86 21 5666 7799"].exists)

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w4i2-structured-multiple-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["scan-recognition-retake"].tap()
        closeScanner(app)
    }

    // MARK: - Week 4 Increment 3: T11 manual correction

    /// Enters the P05 form via the deterministic success fixture and
    /// taps the 编辑 entry into S05 manualEditing.
    @discardableResult
    @MainActor
    private func enterManualEditingOnSuccessFixture(_ app: XCUIApplication) -> XCUIElement {
        app.buttons["scan-crop-confirm"].tap()

        let form = app.descendants(matching: .any)["scan-recognition-form"]
        XCTAssertTrue(form.waitForExistence(timeout: 5),
                      "Confirm must enter the P05 structured recognition form.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-recognition-structured"].exists,
                      "Success fixture must settle in structuredResultAvailable.")

        app.buttons["scan-recognition-edit"].tap()

        let marker = app.descendants(matching: .any)["scan-recognition-manual-editing"]
        XCTAssertTrue(marker.waitForExistence(timeout: 5),
                      "编辑 must enter S05 manualEditing.")
        return form
    }

    /// Fixture-driven T11 regression: read-only P05 → 编辑 →
    /// inline TextFields. Corrections (name / company / mobile) stay
    /// visible in the editing form and the original extracted values
    /// disappear from the editable rows — the ViewModel draft holds
    /// the corrected intermediate while source/raw OCR remain
    /// untouched (source preservation is asserted in unit tests).
    ///
    /// NON-CLAIM: this is NOT real Vision OCR or a real camera; the
    /// DEBUG success fixture and DebugCropProcessor drive the chain.
    /// The native iOS callout/magnifier itself is system UI and is
    /// not asserted.
    @MainActor
    func testManualCorrectionUpdatesRecognitionDraft() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "success")
        app.buttons["scan-crop-confirm"].tap()

        let form = app.descendants(matching: .any)["scan-recognition-form"]
        XCTAssertTrue(form.waitForExistence(timeout: 5),
                      "Confirm must enter the P05 structured recognition form.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-recognition-structured"].exists,
                      "Success fixture must settle in structuredResultAvailable.")

        // BEFORE: read-only P05 with the original extracted values.
        let beforeShot = XCUIScreen.main.screenshot()
        let beforeAttachment = XCTAttachment(screenshot: beforeShot)
        beforeAttachment.name = "w4i3-before-edit"
        beforeAttachment.lifetime = .keepAlways
        add(beforeAttachment)

        app.buttons["scan-recognition-edit"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-recognition-manual-editing"]
                .waitForExistence(timeout: 5),
            "编辑 must enter S05 manualEditing."
        )

        func editField(_ identifier: String, to newValue: String) {
            let field = app.textFields[identifier]
            XCTAssertTrue(field.waitForExistence(timeout: 5),
                          "Editable field \(identifier) must exist.")
            field.tap()
            // The trailing clear (×) button appears while a focused
            // field is non-empty (REF-edit-02 behavior): clear first,
            // then type the full replacement — no cursor positioning.
            let clearButton = app.buttons["清除"]
            XCTAssertTrue(clearButton.waitForExistence(timeout: 3),
                          "Focused non-empty field must show its clear button.")
            clearButton.tap()
            field.typeText(newValue)
            XCTAssertEqual(field.value as? String, newValue,
                           "Corrected value must remain visible in \(identifier).")
        }

        // Editing starts from the original extracted values.
        let nameField = app.textFields["scan-edit-name"]
        let companyField = app.textFields["scan-edit-company"]
        let mobileField = app.textFields["scan-edit-mobile-0"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "张伟")
        XCTAssertEqual(companyField.value as? String, "上海智云科技有限公司")
        XCTAssertEqual(mobileField.value as? String, "+86 138 0013 8000")

        // Corrections from the fixed T11 scenario.
        editField("scan-edit-name", to: "张伟 修正")
        editField("scan-edit-company", to: "上海智云科技")
        editField("scan-edit-mobile-0", to: "+86 138 0013 8001")

        // AFTER: the corrected intermediate values stay stable and
        // visible; the old extracted strings are no longer presented.
        XCTAssertEqual(app.textFields["scan-edit-name"].value as? String, "张伟 修正")
        XCTAssertEqual(app.textFields["scan-edit-company"].value as? String, "上海智云科技")
        XCTAssertEqual(app.textFields["scan-edit-mobile-0"].value as? String, "+86 138 0013 8001")
        XCTAssertFalse(app.staticTexts["上海智云科技有限公司"].exists,
                       "Original company must be replaced by the corrected value.")
        XCTAssertFalse(app.staticTexts["+86 138 0013 8000"].exists,
                       "Original mobile must be replaced by the corrected value.")
        // Unedited fields keep their extracted values.
        XCTAssertEqual(app.textFields["scan-edit-office-0"].value as? String,
                       "+86 21 5555 1234")
        XCTAssertEqual(app.textFields["scan-edit-email-0"].value as? String,
                       "wei.zhang@zhiyuntech.com")
        XCTAssertEqual(app.textFields["scan-edit-website"].value as? String,
                       "www.zhiyuntech.com")

        let afterShot = XCUIScreen.main.screenshot()
        let afterAttachment = XCTAttachment(screenshot: afterShot)
        afterAttachment.name = "w4i3-after-edit"
        afterAttachment.lifetime = .keepAlways
        add(afterAttachment)

        // Discard the draft via 重拍 → scanner preview.
        app.buttons["scan-recognition-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Retake must discard the draft and return to the scanner preview."
        )
        closeScanner(app)
    }

    /// Fixture-driven T11 regression: editing then 重拍 returns to the
    /// live scanner preview (the draft is discarded — there is no
    /// Save in this increment).
    @MainActor
    func testManualEditingRetakeReturnsToScannerPreview() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "success")
        enterManualEditingOnSuccessFixture(app)

        let nameField = app.textFields["scan-edit-name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        app.buttons["清除"].tap()
        nameField.typeText("临时修改")
        XCTAssertEqual(nameField.value as? String, "临时修改")

        app.buttons["scan-recognition-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Retake from manualEditing must return to the scanner preview."
        )
        XCTAssertFalse(app.descendants(matching: .any)["scan-recognition-manual-editing"].exists,
                       "Retake must leave the manual editing state.")
        closeScanner(app)
    }

    // MARK: - Week 3 Increment 7: full integration tests

    /// Fixture-driven full camera pipeline: authorized → preview →
    /// capture → Crop → confirm → Structured P05 → retake → preview → close.
    @MainActor
    func testCameraWorkflowRunsThroughCropAndStructuredRecognitionThenRetakes() throws {
        let app = launchAndEnterScanner(
            cameraMode: "authorized",
            cropMode: "auto",
            ocrMode: "success"
        )

        // 1. Preview present.
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Camera preview must be present after authorized launch."
        )

        // 2. Capture → Crop.
        app.buttons["scan-capture"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-view"].waitForExistence(timeout: 5),
            "Capture must enter the Crop page."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-boundary"].waitForExistence(timeout: 5),
            "Crop boundary must be present."
        )

        // 3. Confirm → Structured P05.
        app.buttons["scan-crop-confirm"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-recognition-form"].waitForExistence(timeout: 10),
            "Confirm must auto-flow into structured recognition."
        )
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-name"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-mobile-0"].exists)

        // 4. Retake → scanner preview returns.
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w4i2-camera-to-structured-recognition-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["scan-recognition-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Retake must return to the scanner preview."
        )

        // 5. Close Scanner → Card Holder returns.
        closeScanner(app)
    }

    /// Fixture-driven photo import integration: authorized → 相册 →
    /// imported image → shared still pipeline → Crop → confirm →
    /// Structured P05 → retake → scanner preview.
    ///
    /// This is a FIXTURE-DRIVEN integration test. It uses the DEBUG-only
    /// photoImport imported mode. Native PhotosPicker runtime is NOT
    /// INDEPENDENTLY VERIFIED.
    @MainActor
    func testPhotoImportWorkflowRunsThroughCropAndStructuredRecognition() throws {
        let app = launchAndEnterScanner(
            cameraMode: "authorized",
            photoImportMode: "imported",
            cropMode: "auto",
            ocrMode: "success"
        )

        // 1. Preview present.
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Preview must be running before import."
        )

        // 2. 相册 → imported image → Crop.
        app.buttons["scan-photo-import"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-view"].waitForExistence(timeout: 5),
            "Import must enter the Crop page."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-boundary"].waitForExistence(timeout: 5),
            "Crop boundary must be present after import."
        )

        // 3. Confirm → Structured P05.
        app.buttons["scan-crop-confirm"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-recognition-form"].waitForExistence(timeout: 10),
            "Confirm after import must auto-flow into structured recognition."
        )
        XCTAssertTrue(app.descendants(matching: .any)["scan-field-name"].exists)

        // 4. Retake → scanner preview returns.
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "w4i2-import-to-structured-recognition-fixture"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["scan-recognition-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Retake after import must return to the scanner preview."
        )

        closeScanner(app)
    }

    /// Fixture-driven OCR failure recovery: Crop confirm → recognition
    /// failed → scan-recognition-failed exists → no raw text → no Save
    /// → 重拍 → scanner preview returns.
    ///
    /// This is a FIXTURE-DRIVEN regression test. The DEBUG fixture
    /// throws OCRError.recognitionFailed. It verifies that Vision/request
    /// failure is separated from nonCardEmptyResult (S05 distinction).
    @MainActor
    func testOCRFailureShowsStableRecoveryAndRetake() throws {
        let app = launchAndEnterScanner(
            cameraMode: "authorized",
            cropMode: "auto",
            ocrMode: "failure"
        )

        // 1. Capture → Crop.
        app.buttons["scan-capture"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-view"].waitForExistence(timeout: 5),
            "Capture must enter the Crop page."
        )

        // 2. Confirm → OCR failure.
        app.buttons["scan-crop-confirm"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-recognition-failed"].waitForExistence(timeout: 10),
            "OCR failure must present the failed state."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["scan-recognition-raw-text"].exists,
            "Failure must not present raw text."
        )
        XCTAssertFalse(
            app.buttons["保存"].exists,
            "No Save action exists on OCR failure."
        )

        // 3. Retake → scanner preview returns.
        app.buttons["scan-recognition-retake"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "Retake after failure must return to the scanner preview."
        )

        closeScanner(app)
    }

    // MARK: - Week 4 Increment 4: T12 Save (S06 saveSucceeded → P06)

    /// Fixture-driven T12 end-to-end: capture → crop confirm → P05 → 编辑
    /// → correct the name → 保存 → P06 saveSucceeded (✓名片保存成功,
    /// summary strip with the corrected name, 完成, 拍下一张) → 完成 pops
    /// back to the Card Holder, which reloads and lists the saved card
    /// (corrected name visible) → tapping the row opens the saved card's
    /// Detail (T13 closure: corrected name + unedited company visible).
    ///
    /// NON-CLAIM: this is NOT a real camera, real Vision OCR or on-disk
    /// persistence; the DEBUG fixtures drive the chain and the image
    /// assets persist into the in-memory ImageAssetStore. T18 (persistence
    /// across relaunch) is a later increment.
    @MainActor
    func testSaveFlowMaterializesCardIntoHolderAndDetail() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "success")
        enterManualEditingOnSuccessFixture(app)

        // Correct the name through the existing edit row.
        let nameField = app.textFields["scan-edit-name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        XCTAssertTrue(app.buttons["清除"].waitForExistence(timeout: 3))
        app.buttons["清除"].tap()
        nameField.typeText("张伟 修正")
        XCTAssertEqual(nameField.value as? String, "张伟 修正")

        // 保存 → P06 saveSucceeded.
        XCTAssertTrue(app.buttons["scan-recognition-save"].waitForExistence(timeout: 3),
                      "manualEditing must show the 保存 action.")
        app.buttons["scan-recognition-save"].tap()

        let saved = app.descendants(matching: .any)["scan-save-success"]
        XCTAssertTrue(saved.waitForExistence(timeout: 5),
                      "保存 must settle in the P06 Save Result page.")
        XCTAssertTrue(app.staticTexts["名片保存成功"].exists,
                      "P06 must show the success title.")
        XCTAssertTrue(app.buttons["scan-save-done"].exists,
                      "P06 must offer 完成.")
        XCTAssertTrue(app.buttons["scan-save-next"].exists,
                      "P06 must offer 拍下一张.")
        XCTAssertTrue(app.staticTexts["张伟 修正"].exists,
                      "P06 summary must show the corrected name.")
        XCTAssertTrue(app.descendants(matching: .any)["scan-save-thumbnail"].exists,
                      "P06 summary must show the saved card thumbnail strip.")
        // Spec-excluded Reference elements are not built.
        XCTAssertFalse(app.buttons["交换名片"].exists,
                       "交换名片 is spec-excluded and must not exist.")

        let p06Shot = XCUIScreen.main.screenshot()
        let p06Attachment = XCTAttachment(screenshot: p06Shot)
        p06Attachment.name = "w4i4-p06-save-success"
        p06Attachment.lifetime = .keepAlways
        add(p06Attachment)

        // 完成 → Card Holder reloads and immediately lists the saved card.
        app.buttons["scan-save-done"].tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "完成 must pop back to the Card Holder."
        )
        let holderName = app.staticTexts["张伟 修正"]
        XCTAssertTrue(holderName.waitForExistence(timeout: 5),
                      "The saved card must immediately appear in the Holder.")
        XCTAssertFalse(app.descendants(matching: .any)["card-holder-empty"].exists,
                       "A saved card means the Holder is populated.")

        let holderShot = XCUIScreen.main.screenshot()
        let holderAttachment = XCTAttachment(screenshot: holderShot)
        holderAttachment.name = "w4i4-holder-after-save"
        holderAttachment.lifetime = .keepAlways
        add(holderAttachment)

        // Tap the new card row → Detail shows the corrected fields (T13).
        holderName.tap()
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 5),
            "Tapping the saved card row must open its Detail."
        )
        XCTAssertEqual(app.descendants(matching: .any)["card-detail-name"].label,
                       "张伟 修正",
                       "Detail must show the corrected name.")
        XCTAssertTrue(app.staticTexts["上海智云科技有限公司"].exists,
                      "Detail must keep the unedited company.")

        let detailShot = XCUIScreen.main.screenshot()
        let detailAttachment = XCTAttachment(screenshot: detailShot)
        detailAttachment.name = "w4i4-detail-saved-card"
        detailAttachment.lifetime = .keepAlways
        add(detailAttachment)
    }

    /// Fixture-driven T12: 拍下一张 on P06 discards the saved workflow
    /// and returns to a fresh Scanner preview; the saved card stays in
    /// the Holder when the Scanner is later closed.
    @MainActor
    func testCaptureNextAfterSaveReturnsToFreshScanner() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "success")
        enterManualEditingOnSuccessFixture(app)

        app.buttons["scan-recognition-save"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-save-success"].waitForExistence(timeout: 5),
            "保存 must settle in the P06 Save Result page."
        )

        app.buttons["scan-save-next"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-camera-preview"].waitForExistence(timeout: 5),
            "拍下一张 must return to a fresh scanner preview."
        )
        XCTAssertFalse(app.descendants(matching: .any)["scan-save-success"].exists,
                       "The P06 page must be discarded after 拍下一张.")

        // Closing the Scanner returns to the Holder with the saved card.
        closeScanner(app)
        XCTAssertTrue(app.staticTexts["张伟"].waitForExistence(timeout: 5),
                      "The saved card must remain listed in the Holder.")
    }

    /// Fixture-driven T12 calibration: a complete structured result can
    /// be saved DIRECTLY from the read-only P05 form — 编辑 and 保存 are
    /// BOTH offered, and tapping 保存 without ever tapping 编辑 settles
    /// the P06 Save Result with the extracted values, then 完成 pops
    /// back to the Card Holder listing the directly saved card.
    @MainActor
    func testStructuredResultCanSaveWithoutEditing() throws {
        let app = enterCropPage(cropMode: "auto", ocrMode: "success")

        app.buttons["scan-crop-confirm"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-recognition-structured"].waitForExistence(timeout: 5),
            "Confirmed crop with success OCR must present the structured P05 form."
        )

        // Read-only P05: 编辑 and 保存 are BOTH present.
        XCTAssertTrue(
            app.buttons["scan-recognition-edit"].waitForExistence(timeout: 5),
            "The read-only P05 form must offer 编辑."
        )
        XCTAssertTrue(
            app.buttons["scan-recognition-save"].waitForExistence(timeout: 5),
            "The read-only P05 form must offer 保存."
        )

        let readyShot = XCUIScreen.main.screenshot()
        let readyAttachment = XCTAttachment(screenshot: readyShot)
        readyAttachment.name = "w4i4-direct-save-ready"
        readyAttachment.lifetime = .keepAlways
        add(readyAttachment)

        // Save DIRECTLY — this flow never taps Edit.
        app.buttons["scan-recognition-save"].tap()

        let saved = app.descendants(matching: .any)["scan-save-success"]
        XCTAssertTrue(
            saved.waitForExistence(timeout: 5),
            "Direct save must settle in the P06 Save Result page."
        )
        XCTAssertTrue(app.staticTexts["名片保存成功"].exists,
                      "P06 must show the success title.")
        XCTAssertTrue(app.staticTexts["张伟"].exists,
                      "The P06 summary must show the extracted name.")
        XCTAssertTrue(app.buttons["scan-save-done"].exists,
                      "P06 must offer 完成.")

        // 完成 → Card Holder reloads and lists the directly saved card.
        app.buttons["scan-save-done"].tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "完成 must pop back to the Card Holder."
        )
        XCTAssertTrue(
            app.staticTexts["张伟"].waitForExistence(timeout: 5),
            "The directly saved card must appear in the Holder."
        )
    }
}
