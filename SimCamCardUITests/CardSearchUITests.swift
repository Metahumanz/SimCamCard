//
//  CardSearchUITests.swift
//  SimCamCardUITests
//
//  T15 Search UI tests (XCTest), Week 4 Increment 6.
//
//  Spec sources:
//   - spec/reference-tests.md T15 Search (black-box evidence directly
//     verifies name and company; final implementation must also support
//     job title, phone and email)
//   - spec/page-inventory.md P08 Search Results
//   - spec/state-inventory.md S01 `searching`
//   - Evidence: evidence/screenshots/REF-search-01-by-name.png,
//     evidence/screenshots/REF-search-02-by-company.png
//
//  Real navigation flow under test:
//   launch populated fixture → Holder search entry → P08 Search Results
//   → type query → same-style card rows → tap result → existing Card
//   Detail → back → search survives → clear / back → full Holder.
//
//  Membership only: rows are located by card-row-<UUID>; row position and
//  accessibility node counts are never asserted (see
//  CardHolderPopulatedUITests for the rationale).
//
//  Fixture: -SimCamCardFixture populated → MockBusinessCards.all:
//   card 001 张伟 / 产品总监 | Product Director / 上海智云科技有限公司
//            phones +86 138 0013 8000, +86 21 5555 1234
//            email wei.zhang@zhiyuntech.com
//   card 002 李娜 / 市场总监 | Marketing Director / 上海智云科技有限公司
//            phone +86 139 1234 5678 / lina.li@zhiyuntech.com
//   card 004 张伟 (minimal: name + phone +86 138 0013 8000 only)
//

import XCTest

final class CardSearchUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Fixture identifiers (mirror MockBusinessCards.swift)

    private let card001RowID = "card-row-00000000-0000-0000-0000-000000000001"
    private let card002RowID = "card-row-00000000-0000-0000-0000-000000000002"
    private let card004RowID = "card-row-00000000-0000-0000-0000-000000000004"

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

    /// Holder → P08 Search Results; returns the live search field.
    @MainActor
    @discardableResult
    private func openSearch(_ app: XCUIApplication) -> XCUIElement {
        let entry = app.descendants(matching: .any)["card-holder-search-entry"]
            .firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 5),
                      "The Holder must offer the search entry bar.")
        entry.tap()

        let field = app.textFields["card-holder-search"]
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Tapping the entry must present the P08 search field.")
        return field
    }

    /// Replaces the search field content via the in-field × clear.
    @MainActor
    private func search(_ app: XCUIApplication, _ query: String) {
        let field = app.textFields["card-holder-search"]
        field.tap()
        if app.buttons["card-holder-search-clear"].exists {
            app.buttons["card-holder-search-clear"].tap()
        }
        field.typeText(query)
        XCTAssertEqual(field.value as? String, query)
    }

    @MainActor
    private func row(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id]
    }

    /// Back from the pushed Card Detail to the Search Results page.
    @MainActor
    private func backFromDetail(_ app: XCUIApplication) {
        app.navigationBars["名片详情"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.textFields["card-holder-search"].waitForExistence(timeout: 5),
            "Back must return to the Search Results page."
        )
    }

    // MARK: - T15 name (Reference REF-search-01)

    @MainActor
    func testSearchByNameOpensExpectedCard() throws {
        let app = launchPopulated()
        openSearch(app)
        search(app, "张伟")

        // 张伟 matches card 001 AND the minimal card 004; card 002 (李娜)
        // must be filtered out.
        XCTAssertTrue(row(app, card001RowID).exists,
                      "Name search must list card 001.")
        XCTAssertTrue(row(app, card004RowID).exists,
                      "Name search must list the minimal card 004.")
        XCTAssertFalse(row(app, card002RowID).exists,
                       "Name search must not list card 002.")

        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "w4i6-search-name"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Tap the result → the SAME Detail navigation as from the Holder.
        row(app, card001RowID).firstMatch.tap()
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 5),
            "A search result must open the Card Detail."
        )
        XCTAssertTrue(app.staticTexts["张伟"].exists)

        // Back returns to the still-active search (query survives the
        // Detail round trip).
        backFromDetail(app)
        XCTAssertEqual(
            app.textFields["card-holder-search"].value as? String, "张伟"
        )
        XCTAssertTrue(row(app, card001RowID).exists)

        // Clear → the full snapshot is restored in place.
        app.buttons["card-holder-search-clear"].tap()
        XCTAssertTrue(row(app, card001RowID).exists)
        XCTAssertTrue(row(app, card002RowID).exists)
        XCTAssertTrue(row(app, card004RowID).exists)

        // Back → full Holder restored.
        app.buttons["card-search-back"].tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 5),
            "Back must return to the Card Holder."
        )
        XCTAssertTrue(row(app, card001RowID).exists)
        XCTAssertTrue(row(app, card002RowID).exists)
        XCTAssertTrue(row(app, card004RowID).exists)
        XCTAssertFalse(
            app.descendants(matching: .any)["card-holder-empty"].exists
        )
    }

    // MARK: - T15 company (Reference REF-search-02)

    @MainActor
    func testSearchByCompanyReturnsExpectedCard() throws {
        let app = launchPopulated()
        openSearch(app)
        search(app, "智云")

        // Both 001 and 002 work at 上海智云科技有限公司; minimal card 004
        // has no company and must not be fabricated into the results.
        XCTAssertTrue(row(app, card001RowID).exists)
        XCTAssertTrue(row(app, card002RowID).exists)
        XCTAssertFalse(row(app, card004RowID).exists)

        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "w4i6-search-company"
        attachment.lifetime = .keepAlways
        add(attachment)

        // The company result opens the expected card's Detail.
        row(app, card002RowID).firstMatch.tap()
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["李娜"].exists,
                      "The card 002 Detail must show 李娜.")

        backFromDetail(app)

        // Back without clearing also restores the full Holder.
        app.buttons["card-search-back"].tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(row(app, card001RowID).exists)
        XCTAssertTrue(row(app, card002RowID).exists)
        XCTAssertTrue(row(app, card004RowID).exists)
    }

    // MARK: - T15 assignment-required fields: jobTitle / phone / email,
    //         no-result state, and clear restore (single continuous
    //         scenario to avoid repeated launches).

    @MainActor
    func testSearchAcrossJobTitlePhoneEmailNoResultAndClear() throws {
        let app = launchPopulated()
        openSearch(app)

        // jobTitle — only card 001 is a Product Director.
        search(app, "Product Director")
        XCTAssertTrue(row(app, card001RowID).exists)
        XCTAssertFalse(row(app, card002RowID).exists)
        XCTAssertFalse(row(app, card004RowID).exists)
        app.buttons["card-holder-search-clear"].tap()

        // phone — digits-only query against formatted stored numbers;
        // card 001 and card 004 share 138 0013 8000, card 002 does not.
        search(app, "13800138000")
        XCTAssertTrue(row(app, card001RowID).exists)
        XCTAssertTrue(row(app, card004RowID).exists)
        XCTAssertFalse(row(app, card002RowID).exists)
        app.buttons["card-holder-search-clear"].tap()

        // email — local part hit, card 001 only (004 has no email).
        search(app, "wei.zhang")
        XCTAssertTrue(row(app, card001RowID).exists)
        XCTAssertFalse(row(app, card002RowID).exists)
        XCTAssertFalse(row(app, card004RowID).exists)

        // Zero hits → the dedicated search no-result state, distinct
        // from the Holder's own empty state.
        search(app, "查无此名片")
        XCTAssertTrue(
            app.descendants(matching: .any)["card-holder-search-empty"]
                .waitForExistence(timeout: 3)
        )
        XCTAssertFalse(row(app, card001RowID).exists)
        XCTAssertFalse(row(app, card002RowID).exists)
        XCTAssertFalse(row(app, card004RowID).exists)

        // Clear → all results restored in the Search page, then back
        // restores the populated Holder.
        app.buttons["card-holder-search-clear"].tap()
        XCTAssertTrue(row(app, card001RowID).exists)
        XCTAssertTrue(row(app, card002RowID).exists)
        XCTAssertTrue(row(app, card004RowID).exists)
        XCTAssertFalse(
            app.descendants(matching: .any)["card-holder-search-empty"].exists
        )

        app.buttons["card-search-back"].tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(row(app, card001RowID).exists)
        XCTAssertTrue(row(app, card002RowID).exists)
        XCTAssertTrue(row(app, card004RowID).exists)
    }
}
