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
}
