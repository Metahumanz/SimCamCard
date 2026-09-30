//
//  CardDetailUITests.swift
//  SimCamCardUITests
//
//  T13 — Card Detail UI tests (XCTest), read-only skeleton.
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail
//   - spec/state-inventory.md S06 detailCollapsed
//   - spec/reference-tests.md T13 Detail ("Saved structured fields are
//     visible in detail view.")
//   - spec/data-model.md §Multi-value observation (phones[] kinds,
//     emails[]), §Missing-field rule
//   - Evidence: evidence/screenshots/REF-detail-01-collapsed.png,
//     evidence/screenshots/REF-detail-03-after-edit-expanded.png
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
    private func launchPopulated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-SimCamCardFixture", "populated"]
        app.launch()
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
}
