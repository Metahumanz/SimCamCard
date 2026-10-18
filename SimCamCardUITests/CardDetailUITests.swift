//
//  CardDetailUITests.swift
//  SimCamCardUITests
//
//  T13 — Card Detail UI tests (XCTest), read-only skeleton, plus T14
//  Existing-Card Editing UI tests.
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail
//   - spec/state-inventory.md S06 detailCollapsed
//   - spec/reference-tests.md T13 Detail ("Saved structured fields are
//     visible in detail view."), T14 Existing-Card Editing ("edited title
//     → stored BusinessCard changes → Detail displays corrected title")
//   - spec/data-model.md §Multi-value observation (phones[] kinds,
//     emails[]), §Missing-field rule
//   - Evidence: evidence/screenshots/REF-detail-01-collapsed.png,
//     evidence/screenshots/REF-detail-03-after-edit-expanded.png,
//     evidence/screenshots/REF-edit-01-before-change.png,
//     evidence/screenshots/REF-edit-02-after-title-change.png
//
//  Real navigation flow under test:
//   launch populated fixture → locate fixed-UUID holder row → TAP →
//   NavigationStack pushes Card Detail.
//
//  Fixture: launch argument `-SimCamCardFixture populated` seeds
//  MockBusinessCards.all (card 001 full bilingual multi-phone, card 002
//  missing website, card 004 minimal name+mobile). DEBUG-only.
//
//  Cases:
//   1. Full card 001: Detail shows name / title / company / both phones
//      with kind labels / email / website / address. Then Back returns to
//      the still-populated holder.
//   2. Minimal card 004: Detail shows name + the single mobile only;
//      company / title / website / address / email rows do NOT exist and
//      no office-phone label is shown (T20 no-fabrication negative case).
//
//  Membership only — no row-position dependency; rows are located by the
//  same fixed UUID identifiers the holder uses.
//

import XCTest

final class CardDetailUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Fixture identifiers (mirror MockBusinessCards.swift)

    private let card001RowID = "card-row-00000000-0000-0000-0000-000000000001"
    private let card004RowID = "card-row-00000000-0000-0000-0000-000000000004"

    private let card001MobileRowID = "card-detail-phone-10000000-0000-0000-0000-000000000001"
    private let card001OfficeRowID = "card-detail-phone-10000000-0000-0000-0000-000000000002"
    private let card004MobileRowID = "card-detail-phone-40000000-0000-0000-0000-000000000001"

    /// Launches the app with the populated deterministic fixture.
    @MainActor
    private func launchPopulated() -> XCUIApplication {
        let app = UITestAppFactory.launchEphemeral(
            arguments: ["-SimCamCardFixture", "populated"]
        )
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Card Holder should be visible after launch."
        )
        return app
    }

    /// Taps a holder row identified by `card-row-<UUID>` and waits for
    /// the Card Detail navigation bar.
    private func openDetail(forRow rowID: String, app: XCUIApplication) {
        let row = app.descendants(matching: .any)[rowID].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Row \(rowID) should exist.")
        row.tap()

        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 10),
            "Card Detail should be pushed after tapping the card row."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail"].exists,
            "Card Detail root 'card-detail' should exist."
        )
    }

    // MARK: - T13 full fixture

    @MainActor
    func testCardDetailShowsFullFixtureFields() throws {
        let app = launchPopulated()
        openDetail(forRow: card001RowID, app: app)

        // Header fields (evidence-supported).
        XCTAssertTrue(app.staticTexts["张伟"].exists, "Name '张伟' should be visible.")
        XCTAssertTrue(
            app.staticTexts["产品总监 | Product Director"].exists,
            "Job title should be visible."
        )
        XCTAssertTrue(
            app.staticTexts["上海智云科技有限公司"].exists,
            "Company should be visible."
        )

        // Multi-value phones: both rows exist by stable PhoneNumber id,
        // values and kind labels are visible.
        XCTAssertTrue(
            app.descendants(matching: .any)[card001MobileRowID].exists,
            "Mobile phone row should exist."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[card001OfficeRowID].exists,
            "Office phone row should exist."
        )
        XCTAssertTrue(app.staticTexts["+86 138 0013 8000"].exists, "Mobile value should be visible.")
        XCTAssertTrue(app.staticTexts["+86 21 5555 1234"].exists, "Office value should be visible.")
        XCTAssertTrue(app.staticTexts["手机"].exists, "Mobile kind label '手机' should be visible.")
        XCTAssertTrue(app.staticTexts["工作电话"].exists, "Office kind label '工作电话' should be visible.")

        // Email.
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-email-0"].exists,
            "Email row should exist."
        )
        XCTAssertTrue(app.staticTexts["wei.zhang@zhiyuntech.com"].exists, "Email value should be visible.")
        XCTAssertTrue(app.staticTexts["邮箱"].exists, "Email label '邮箱' should be visible.")

        // Website + address.
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-website"].exists,
            "Website row should exist."
        )
        XCTAssertTrue(app.staticTexts["www.zhiyuntech.com"].exists, "Website value should be visible.")
        XCTAssertTrue(app.staticTexts["首页"].exists, "Website label '首页' should be visible.")

        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-address"].exists,
            "Address row should exist."
        )
        XCTAssertTrue(
            app.staticTexts["上海市浦东新区世纪大道100号 200120"].exists,
            "Address value should be visible."
        )
        XCTAssertTrue(app.staticTexts["公司地址"].exists, "Address label '公司地址' should be visible.")

        // Read-only skeleton: no edit/delete/action controls from
        // deferred increments are presented as functional UI.
        XCTAssertFalse(
            app.staticTexts["Coming soon"].exists,
            "No development placeholder text should be shown."
        )

        // Validation evidence (separate from frozen REF-* screenshots).
        let detailScreenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: detailScreenshot)
        attachment.name = "increment5-card-detail-001-full"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Back returns to the still-populated Card Holder.
        app.navigationBars["名片详情"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Back should return to the Card Holder."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[card001RowID].exists,
            "Holder rows should still be present after returning."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["card-holder-empty"].exists,
            "Holder should still be populated after returning from Detail."
        )
    }

    // MARK: - T20 minimal-card negative case

    @MainActor
    func testCardDetailMinimalCardDoesNotFabricateFields() throws {
        let app = launchPopulated()
        openDetail(forRow: card004RowID, app: app)

        // Present: name + single mobile.
        XCTAssertTrue(app.staticTexts["张伟"].exists, "Minimal card name '张伟' should be visible.")
        XCTAssertTrue(
            app.descendants(matching: .any)[card004MobileRowID].exists,
            "The single mobile phone row should exist."
        )
        XCTAssertTrue(app.staticTexts["+86 138 0013 8000"].exists, "Mobile value should be visible.")
        XCTAssertTrue(app.staticTexts["手机"].exists, "Mobile label '手机' should be visible.")

        // Absent fields must not be fabricated: no header rows, no
        // website/address rows, no email rows.
        XCTAssertFalse(
            app.descendants(matching: .any)["card-detail-company"].exists,
            "Company row must not exist for the minimal card."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["card-detail-job-title"].exists,
            "Job-title row must not exist for the minimal card."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["card-detail-website"].exists,
            "Website row must not exist for the minimal card."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["card-detail-address"].exists,
            "Address row must not exist for the minimal card."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["card-detail-email-0"].exists,
            "No email row must exist for the minimal card."
        )

        // No other phone kinds: the office label must not appear.
        XCTAssertFalse(
            app.staticTexts["工作电话"].exists,
            "Office phone label must not appear for the minimal card."
        )

        // Fixture values belonging to card 001 must not leak in.
        XCTAssertFalse(app.staticTexts["上海智云科技有限公司"].exists, "No company text may be fabricated.")
        XCTAssertFalse(app.staticTexts["www.zhiyuntech.com"].exists, "No website text may be fabricated.")
        XCTAssertFalse(app.staticTexts["wei.zhang@zhiyuntech.com"].exists, "No email text may be fabricated.")

        // Validation evidence (separate from frozen REF-* screenshots).
        let detailScreenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: detailScreenshot)
        attachment.name = "increment5-card-detail-004-minimal"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - T14 Existing-Card Editing

    private let oldTitle = "产品总监 | Product Director"
    private let newTitle = "高级产品总监 | Senior Product Director"
    private let card002RowID = "card-row-00000000-0000-0000-0000-000000000002"

    /// Holder row secondary line: "jobTitle · company" (BusinessCardRow).
    private var holderOldSecondary: String {
        "\(oldTitle) · 上海智云科技有限公司"
    }
    private var holderNewSecondary: String {
        "\(newTitle) · 上海智云科技有限公司"
    }

    /// Opens the 编辑名片 sheet from an already-visible card-001 Detail
    /// and verifies the prefilled form (existing values, stable ids).
    @MainActor
    private func openEditForm(_ app: XCUIApplication) {
        let editButton = app.buttons["card-detail-edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5),
                      "The Detail must offer the 编辑 entry.")
        editButton.tap()

        XCTAssertTrue(
            app.navigationBars["编辑名片"].waitForExistence(timeout: 5),
            "Tapping 编辑 must present the 编辑名片 page."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-edit"].exists,
            "The edit page root marker must exist."
        )

        // Prefilled existing values (no fabricated / lost content).
        let titleField = app.textFields["card-edit-job-title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        XCTAssertEqual(titleField.value as? String, oldTitle,
                       "The edit form must prefill the saved title.")
        XCTAssertEqual(
            app.textFields["card-edit-phone-10000000-0000-0000-0000-000000000001"].value as? String,
            "+86 138 0013 8000"
        )
        XCTAssertEqual(
            app.textFields["card-edit-phone-10000000-0000-0000-0000-000000000002"].value as? String,
            "+86 21 5555 1234"
        )
        XCTAssertEqual(app.textFields["card-edit-email-0"].value as? String,
                       "wei.zhang@zhiyuntech.com")
        XCTAssertEqual(app.textFields["card-edit-website"].value as? String,
                       "www.zhiyuntech.com")
        XCTAssertTrue(app.buttons["card-edit-cancel"].exists)
        XCTAssertTrue(app.buttons["card-edit-save"].exists)
    }

    /// Replaces a focused non-empty edit field's full value using the
    /// Reference-style focus clear (×) affordance, then types.
    @MainActor
    private func replaceField(_ app: XCUIApplication, identifier: String, with value: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        let clearButton = app.buttons["清除"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 3),
                      "A focused non-empty edit field must show its clear button.")
        clearButton.tap()
        field.typeText(value)
        XCTAssertEqual(field.value as? String, value)
    }

    @MainActor
    func testExistingCardTitleEditPersistsToDetail() throws {
        let app = launchPopulated()
        openDetail(forRow: card001RowID, app: app)

        // BEFORE: Detail shows the original title.
        XCTAssertTrue(app.staticTexts[oldTitle].exists,
                      "The Detail must show the original title before edit.")
        let beforeShot = XCUIScreen.main.screenshot()
        let beforeAttachment = XCTAttachment(screenshot: beforeShot)
        beforeAttachment.name = "w4i5-existing-edit-before"
        beforeAttachment.lifetime = .keepAlways
        add(beforeAttachment)

        openEditForm(app)

        let formShot = XCUIScreen.main.screenshot()
        let formAttachment = XCTAttachment(screenshot: formShot)
        formAttachment.name = "w4i5-existing-edit-form"
        formAttachment.lifetime = .keepAlways
        add(formAttachment)

        // Fixed Reference correction.
        replaceField(app, identifier: "card-edit-job-title", with: newTitle)

        app.buttons["card-edit-save"].tap()

        // Save returns to the same Detail, which must immediately show
        // the corrected title (no pop to the Holder required).
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 5),
            "Save must return to the Card Detail."
        )
        XCTAssertFalse(
            app.navigationBars["编辑名片"].exists,
            "The edit page must be dismissed after save."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-job-title"].waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            app.descendants(matching: .any)["card-detail-job-title"].label,
            newTitle,
            "The Detail must display the corrected title immediately."
        )
        XCTAssertFalse(app.staticTexts[oldTitle].exists,
                       "The old title must be gone from the Detail.")

        // Existing phone identities survive — same row ids, same values.
        XCTAssertTrue(app.descendants(matching: .any)[card001MobileRowID].exists)
        XCTAssertTrue(app.descendants(matching: .any)[card001OfficeRowID].exists)
        XCTAssertTrue(app.staticTexts["+86 138 0013 8000"].exists)
        XCTAssertTrue(app.staticTexts["+86 21 5555 1234"].exists)

        let afterShot = XCUIScreen.main.screenshot()
        let afterAttachment = XCTAttachment(screenshot: afterShot)
        afterAttachment.name = "w4i5-existing-edit-after"
        afterAttachment.lifetime = .keepAlways
        add(afterAttachment)

        // Back to the Holder: onAppear reload from the same shared
        // repository shows the corrected row.
        app.navigationBars["名片详情"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Back must return to the Card Holder."
        )
        let row = app.descendants(matching: .any)[card001RowID].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(
            row.staticTexts[holderNewSecondary].exists,
            "The holder row must show the corrected title after reload."
        )
        XCTAssertFalse(
            row.staticTexts[holderOldSecondary].exists,
            "The holder row must no longer show the old title."
        )

        // Duplicate regression: editing must not add a card — the other
        // fixture rows are still present and the edited row keeps its id.
        XCTAssertTrue(app.descendants(matching: .any)[card002RowID].exists)
        XCTAssertTrue(app.descendants(matching: .any)[card004RowID].exists)
    }

    @MainActor
    func testExistingCardEditCancelDiscardsChanges() throws {
        let app = launchPopulated()
        openDetail(forRow: card001RowID, app: app)

        app.buttons["card-detail-edit"].tap()
        XCTAssertTrue(
            app.navigationBars["编辑名片"].waitForExistence(timeout: 5)
        )
        replaceField(app, identifier: "card-edit-job-title", with: newTitle)

        // Cancel discards the draft — returns to Detail with the
        // original title.
        app.buttons["card-edit-cancel"].tap()
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 5),
            "Cancel must return to the Card Detail."
        )
        XCTAssertTrue(app.staticTexts[oldTitle].exists,
                      "Cancel must restore the original title.")
        XCTAssertFalse(app.staticTexts[newTitle].exists)

        // Back to the Holder: repository was never touched.
        app.navigationBars["名片详情"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10)
        )
        let row = app.descendants(matching: .any)[card001RowID].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(row.staticTexts[holderOldSecondary].exists)
        XCTAssertFalse(row.staticTexts[holderNewSecondary].exists)
    }

    // MARK: - B-01 Phone/Email/Website tap behavior

    /// Assignment §10: "Tap phone number; Tap email address; Tap website."
    ///
    /// The Simulator cannot complete real calls/emails/browser opens, so
    /// this test verifies the URL-initiation side only: each row exists as
    /// a hittable element (the Button wrapper is present). The actual
    /// external-app handoff (Phone/Mail/Safari) is a system-level concern
    /// verified separately by the URL-construction Unit tests
    /// (CardDetailURLMappingTests).
    @MainActor
    func testCardDetailPhoneEmailWebsiteRowsAreTappable() throws {
        let app = launchPopulated()
        openDetail(forRow: card001RowID, app: app)

        // Phone rows: each individually hittable (multi-phone preserved).
        let mobileRow = app.descendants(matching: .any)[card001MobileRowID].firstMatch
        XCTAssertTrue(mobileRow.waitForExistence(timeout: 5),
                      "Mobile phone row must exist.")
        XCTAssertTrue(mobileRow.isHittable,
                      "Mobile phone row must be hittable (tap action wired).")

        let officeRow = app.descendants(matching: .any)[card001OfficeRowID].firstMatch
        XCTAssertTrue(officeRow.exists,
                      "Office phone row must exist.")
        XCTAssertTrue(officeRow.isHittable,
                      "Office phone row must be hittable (tap action wired).")

        // Email row.
        let emailRow = app.descendants(matching: .any)["card-detail-email-0"].firstMatch
        XCTAssertTrue(emailRow.exists, "Email row must exist.")
        XCTAssertTrue(emailRow.isHittable,
                      "Email row must be hittable (tap action wired).")

        // Website row.
        let websiteRow = app.descendants(matching: .any)["card-detail-website"].firstMatch
        XCTAssertTrue(websiteRow.exists, "Website row must exist.")
        XCTAssertTrue(websiteRow.isHittable,
                      "Website row must be hittable (tap action wired).")

        // Address row exists but has no tap action (not in §10 must-tap list).
        let addressRow = app.descendants(matching: .any)["card-detail-address"].firstMatch
        XCTAssertTrue(addressRow.exists, "Address row must exist.")
    }

    /// Minimal card (004): its single phone row is also tappable;
    /// absent fields (email/website/address) have no rows to tap.
    @MainActor
    func testCardDetailMinimalCardPhoneRowIsTappable() throws {
        let app = launchPopulated()
        openDetail(forRow: card004RowID, app: app)

        let mobileRow = app.descendants(matching: .any)[card004MobileRowID].firstMatch
        XCTAssertTrue(mobileRow.waitForExistence(timeout: 5),
                      "Minimal card's phone row must exist.")
        XCTAssertTrue(mobileRow.isHittable,
                      "Minimal card's phone row must be hittable.")

        // No email/website/address rows to tap on the minimal card.
        XCTAssertFalse(app.descendants(matching: .any)["card-detail-email-0"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["card-detail-website"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["card-detail-address"].exists)
    }

    // MARK: - B-02 Original image viewing

    /// The ephemeral fixture has no image bytes in the store, so the original
    /// image section must NOT appear — this verifies graceful degradation.
    /// All existing Detail/Edit/Delete/Notes/Export flows remain unaffected.
    @MainActor
    func testCardDetailMissingOriginalImageGracefulDegradation() throws {
        let app = launchPopulated()
        openDetail(forRow: card001RowID, app: app)

        // Original image thumbnail should be absent (no bytes in fixture store).
        let originalImage = app.descendants(matching: .any)["card-detail-original-image"].firstMatch
        XCTAssertFalse(originalImage.exists,
                       "Missing original image must not render the image section.")

        // Existing structured fields and actions must still be present and
        // unaffected (T13/T14/T17/T19 baseline preserved).
        XCTAssertTrue(app.staticTexts["张伟"].exists, "Name must remain visible.")
        XCTAssertTrue(
            app.descendants(matching: .any)[card001MobileRowID].exists,
            "Phone row must remain visible."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-email-0"].exists,
            "Email row must remain visible."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-edit"].exists,
            "Edit entry must remain visible."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-more"].exists,
            "More actions entry must remain visible."
        )
    }

    // MARK: - B-01 URL-initiation evidence (DEBUG-only openURL capture)
    //
    // The Simulator has no Phone/Mail/Safari receiver, so the previous
    // `isHittable` assertions could not prove that the CORRECT URL was
    // initiated. With `-SimCamCardCaptureOpenURL 1` the App root replaces
    // the SwiftUI openURL action with a recorder that captures the exact
    // absoluteString and does NOT forward it to any system app. These tests
    // therefore assert the initiated URL, not merely tappability.

    /// Launches with the DEBUG openURL recorder installed.
    @MainActor
    private func launchPopulatedWithURLCapture() -> XCUIApplication {
        let app = UITestAppFactory.launchEphemeral(
            arguments: [
                "-SimCamCardFixture", "populated",
                "-SimCamCardCaptureOpenURL", "1",
            ]
        )
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Card Holder should be visible after launch."
        )
        return app
    }

    /// Waits until the capture element reports `expectedURL` as its label.
    @MainActor
    private func assertCapturedURL(
        _ expectedURL: String,
        app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let log = app.descendants(matching: .any)["debug-open-url-log"].firstMatch
        XCTAssertTrue(
            log.waitForExistence(timeout: 5),
            "The DEBUG openURL capture element must exist.",
            file: file,
            line: line
        )
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expectedURL),
            object: log
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(
            result,
            .completed,
            "captured URL = '\(log.label)'; expected '\(expectedURL)'",
            file: file,
            line: line
        )
    }

    /// Assignment §10 must-tap rows: mobile phone, office phone, email and
    /// website must each initiate the correct native URL.
    @MainActor
    func testCardDetailRowTapInitiatesCorrectURL() throws {
        let app = launchPopulatedWithURLCapture()
        openDetail(forRow: card001RowID, app: app)

        // Mobile phone → tel:
        let mobileRow = app.descendants(matching: .any)[card001MobileRowID].firstMatch
        XCTAssertTrue(mobileRow.waitForExistence(timeout: 5),
                      "Mobile phone row must exist.")
        mobileRow.tap()
        assertCapturedURL("tel:+86%20138%200013%208000", app: app)

        // Office phone → tel:
        let officeRow = app.descendants(matching: .any)[card001OfficeRowID].firstMatch
        XCTAssertTrue(officeRow.waitForExistence(timeout: 5),
                      "Office phone row must exist.")
        officeRow.tap()
        assertCapturedURL("tel:+86%2021%205555%201234", app: app)

        // Email and website may sit below the fold on the full card.
        app.swipeUp()

        // Email → mailto:
        let emailRow = app.descendants(matching: .any)["card-detail-email-0"].firstMatch
        XCTAssertTrue(emailRow.waitForExistence(timeout: 5),
                      "Email row must exist.")
        emailRow.tap()
        assertCapturedURL("mailto:wei.zhang@zhiyuntech.com", app: app)

        // Website → https:
        let websiteRow = app.descendants(matching: .any)["card-detail-website"].firstMatch
        XCTAssertTrue(websiteRow.waitForExistence(timeout: 5),
                      "Website row must exist.")
        websiteRow.tap()
        assertCapturedURL("https://www.zhiyuntech.com", app: app)

        // Evidence: the Detail after the four captured taps.
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "w4i13-b01-url-capture"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Negative: the address row is NOT in the §10 must-tap list, so tapping
    /// it must not initiate any URL (the recorder stays empty).
    @MainActor
    func testCardDetailAddressRowDoesNotInitiateURL() throws {
        let app = launchPopulatedWithURLCapture()
        openDetail(forRow: card001RowID, app: app)

        app.swipeUp()
        let addressRow = app.descendants(matching: .any)["card-detail-address"].firstMatch
        XCTAssertTrue(addressRow.waitForExistence(timeout: 5),
                      "Address row must exist.")
        addressRow.tap()

        let log = app.descendants(matching: .any)["debug-open-url-log"].firstMatch
        if log.waitForExistence(timeout: 2) {
            XCTAssertEqual(log.label, "",
                           "Address row must not initiate any URL.")
        }
    }
}
