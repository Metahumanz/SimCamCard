//
//  CardContactExportUITests.swift
//  SimCamCardUITests
//
//  Week 4 Increment 11 — T19 Contact Export UI tests.
//
//  Spec sources:
//   - spec/page-inventory.md P11 Contact Export (App + System)
//   - spec/state-inventory.md S09
//   - spec/reference-tests.md T19
//   - Evidence: REF-export-01..05, REF-detail-01/04
//
//  Two layers:
//
//  1. Deterministic DEBUG-fake flows (-SimCamCardContactExportMode …)
//     never touch the real CNContactStore:
//       A. allowed       → success surface (more-actions entry)
//       B. allow-on-request → system-prompt stage faked as allowed →
//          success surface (BOTTOM entry; proves the two entries share
//          one workflow)
//       C. deny-on-request → denied surface + Settings/cancel, no success
//       D. denied        → denied surface directly, no prompt, no write
//       E. failure       → failure surface
//
//  2. Native system integration (-SimCamCardContactExportMode system):
//     the REAL SystemContactExporter, the REAL iOS permission alert and
//     a REAL CNSaveRequest. The granted run relies on `simctl privacy
//     grant contacts com.metahumanz.SimCamCard` being set before the
//     gate; the prompt run resets authorization and handles the genuine
//     SpringBoard alert via an interruption monitor (the permission
//     screenshot attachment is captured from that REAL alert — never a
//     Debug fake).
//

import XCTest

final class CardContactExportUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Fixture identifiers (mirror MockBusinessCards.swift)

    private let card001RowID = "card-row-00000000-0000-0000-0000-000000000001"
    private let modeArgument = "-SimCamCardContactExportMode"

    // MARK: - A. pre-allowed export succeeds via the MORE-ACTIONS entry

    @MainActor
    func testFakeAllowedMoreEntryShowsSuccess() throws {
        let app = launch(mode: "allowed")
        openCard001Detail(app)

        app.buttons["card-detail-more"].tap()
        let moreExport = app.buttons.matching(identifier: "card-detail-more-export").firstMatch
        XCTAssertTrue(moreExport.waitForExistence(timeout: 5))
        moreExport.tap()

        assertSuccessSurface(app)
        tapAlertButton(app, "contact-export-success-ok")
        XCTAssertTrue(app.alerts["已保存到通讯录"].waitForNonExistence(timeout: 5))
        // Still on Detail after dismissing the result.
        XCTAssertTrue(app.navigationBars["名片详情"].exists)
    }

    // MARK: - B. notDetermined → allow → success via the BOTTOM entry

    @MainActor
    func testFakeAllowOnRequestBottomEntryShowsSuccess() throws {
        let app = launch(mode: "allow-on-request")
        openCard001Detail(app)

        // REF-detail-01 bottom-left entry. Same workflow as more-actions.
        app.buttons["card-detail-export"].tap()

        assertSuccessSurface(app)
        attachScreenshot(app, name: "w4i11-contact-export-success")
        tapAlertButton(app, "contact-export-success-ok")
    }

    // MARK: - C. notDetermined → deny → denied surface, no success

    @MainActor
    func testFakeDenyOnRequestShowsDeniedSurface() throws {
        let app = launch(mode: "deny-on-request")
        openCard001Detail(app)

        app.buttons["card-detail-export"].tap()
        assertDeniedSurface(app)
        attachScreenshot(app, name: "w4i11-contact-denied")

        // The success surface must never appear; 取消 dismisses the
        // denied result and stays on Detail.
        XCTAssertFalse(app.alerts["已保存到通讯录"].exists)
        tapAlertButton(app, "contact-export-denied-cancel")
        XCTAssertTrue(app.alerts["无法保存名片到通讯录"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["名片详情"].exists)

        // A second attempt re-reports denial — nothing was written.
        app.buttons["card-detail-export"].tap()
        assertDeniedSurface(app)
    }

    // MARK: - D. already denied → denied surface with no prompt

    @MainActor
    func testFakeAlreadyDeniedShowsDeniedSurface() throws {
        let app = launch(mode: "denied")
        openCard001Detail(app)

        app.buttons["card-detail-more"].tap()
        let moreExport = app.buttons.matching(identifier: "card-detail-more-export").firstMatch
        XCTAssertTrue(moreExport.waitForExistence(timeout: 5))
        moreExport.tap()

        assertDeniedSurface(app)
    }

    // MARK: - E. write failure → failure surface

    @MainActor
    func testFakeFailureShowsFailureSurface() throws {
        let app = launch(mode: "failure")
        openCard001Detail(app)

        app.buttons["card-detail-export"].tap()
        let failedAlert = app.alerts["保存到通讯录失败"]
        XCTAssertTrue(
            failedAlert.waitForExistence(timeout: 5),
            "A throwing Contacts write must present the failure surface."
        )
        XCTAssertTrue(alertButton(app, "contact-export-failed-ok").exists)
        tapAlertButton(app, "contact-export-failed-ok")
        XCTAssertTrue(failedAlert.waitForNonExistence(timeout: 5))
    }

    // MARK: - F. REAL system exporter, REAL permission prompt → success
    //
    // Requires `simctl privacy reset/grant contacts` coordination from
    // the targeted/full run (see ai/changes.md W4I11). The attachment
    // captured inside the interruption monitor is the genuine iOS
    // Contacts alert — not a Debug fake.

    @MainActor
    func testSystem01RealPermissionPromptThenSaveSucceeds() throws {
        let app = XCUIApplication()
        // Start from a clean permission decision so the REAL prompt runs.
        app.resetAuthorizationStatus(for: .contacts)
        app.launchArguments = [
            "-SimCamCardStorage", "ephemeral",
            "-SimCamCardFixture", "populated",
            modeArgument, "system"
        ]

        var capturedPrompt = false
        addUIInterruptionMonitor(withDescription: "System Contacts permission") { alert in
            // iOS 18+ presents up to three choices:
            // 不允许 / 仅允许选定的联系人… / 允许全部. Any "允许…" choice
            // grants usable (full or limited) Contacts access; prefer
            // full. Legacy iOS shows a single 允许 button.
            let grantButtons = alert.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "允许")
            )
            guard grantButtons.count > 0 else { return false }
            // Evidence: the real system permission alert (full screen).
            let shot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: shot)
            attachment.name = "w4i11-contact-permission"
            attachment.lifetime = .keepAlways
            self.add(attachment)
            capturedPrompt = true
            let fullAccess = grantButtons.matching(
                NSPredicate(format: "label == %@", "允许全部")
            )
            if fullAccess.count > 0 {
                fullAccess.firstMatch.tap()
            } else {
                grantButtons.firstMatch.tap()
            }
            return true
        }

        app.launch()
        XCTAssertTrue(app.navigationBars["名片夹"].waitForExistence(timeout: 10))
        openCard001Detail(app)

        app.buttons["card-detail-export"].tap()
        // Pump the event loop so the interruption monitor engages with
        // the SpringBoard alert (a neutral tap is the standard trigger).
        let explicitlyHandled = assertSystemExportSucceeds(app)
        XCTAssertTrue(
            capturedPrompt || explicitlyHandled,
            "The real system Contacts permission alert must have been handled."
        )
        tapAlertButton(app, "contact-export-success-ok")
    }

    // MARK: - G. REAL system exporter with granted permission →
    // real CNSaveRequest succeeds.

    @MainActor
    func testSystem02GrantedPermissionRealSaveSucceeds() throws {
        let app = launch(mode: "system")
        openCard001Detail(app)

        app.buttons["card-detail-export"].tap()

        // A real CNContactStore.execute(CNSaveRequest) success is the
        // proof: the exporter throws on failure and the ViewModel would
        // present contact-export-failed instead.
        assertSystemExportSucceeds(app)
        attachScreenshot(app, name: "w4i11-contact-export-success")
        tapAlertButton(app, "contact-export-success-ok")
    }

    // MARK: - Real-system wait (CNContactStore path is slow)

    /// Waits for the genuine export result. While waiting it explicitly
    /// services the SpringBoard permission alert (the interruption
    /// monitor alone is event-latched), pumping a neutral tap each
    /// iteration. A full-screen screenshot is attached on failure so the
    /// real system surface is never guessed.
    @discardableResult
    @MainActor
    private func assertSystemExportSucceeds(_ app: XCUIApplication) -> Bool {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let successAlert = app.alerts["已保存到通讯录"]
        let failedAlert = app.alerts["保存到通讯录失败"]
        let deniedAlert = app.alerts["无法保存名片到通讯录"]

        let deadline = Date().addingTimeInterval(30)
        var promptHandled = false
        while Date() < deadline {
            if successAlert.exists {
                XCTAssertTrue(alertButton(app, "contact-export-success-ok").exists)
                return promptHandled
            }
            if failedAlert.exists {
                attachFullScreen(name: "w4i11-system-failure-debug")
                XCTFail("Real CNSaveRequest failed — the failure surface is presented.")
                return false
            }
            if deniedAlert.exists {
                attachFullScreen(name: "w4i11-system-denied-debug")
                XCTFail("Real Contacts authorization was denied unexpectedly.")
                return false
            }

            // Service the genuine system permission surface. It is hosted
            // in SpringBoard's accessibility tree but NOT always inside
            // an Alert node (the iOS 18+ limited-access management page
            // lives in a plain Window), so buttons are queried globally:
            //  - classic alert: 不允许 / 仅允许选定的联系人… / 允许全部
            //  - management page: 选择联系人 / 共享所有 N 位联系人
            let shareAll = springboard.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "共享所有")
            )
            if shareAll.firstMatch.waitForExistence(timeout: 1) {
                if !promptHandled {
                    attachFullScreen(name: "w4i11-contact-permission")
                    promptHandled = true
                }
                shareAll.firstMatch.tap()
                continue
            }
            let grant = springboard.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "允许")
            )
            if grant.firstMatch.exists {
                if !promptHandled {
                    attachFullScreen(name: "w4i11-contact-permission")
                    promptHandled = true
                }
                let full = grant.matching(NSPredicate(format: "label == %@", "允许全部"))
                (full.count > 0 ? full.firstMatch : grant.firstMatch).tap()
                continue
            }

            // Neutral pump so any registered interruption monitor engages.
            app.navigationBars.firstMatch
                .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
                .tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }

        attachFullScreen(name: "w4i11-system-timeout-debug")
        XCTFail("Timed out waiting for the real export result.")
        return false
    }

    @MainActor
    private func attachFullScreen(name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Helpers

    @MainActor
    private func launch(mode: String) -> XCUIApplication {
        let app = UITestAppFactory.launchEphemeral(arguments: [
            "-SimCamCardFixture", "populated",
            modeArgument, mode
        ])
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Card Holder should be visible after launch."
        )
        return app
    }

    @MainActor
    private func openCard001Detail(_ app: XCUIApplication) {
        let row = app.descendants(matching: .any)[card001RowID].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Card 001 row should exist.")
        row.tap()
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 10),
            "Card Detail should open."
        )
    }

    @MainActor
    private func alertButton(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        // SwiftUI alert buttons surface twice in the AX tree (same
        // frame); always resolve through firstMatch.
        app.buttons.matching(identifier: id).firstMatch
    }

    @MainActor
    private func tapAlertButton(_ app: XCUIApplication, _ id: String) {
        let button = alertButton(app, id)
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    @MainActor
    private func assertSuccessSurface(_ app: XCUIApplication, timeout: TimeInterval = 5) {
        // SwiftUI Alert exposes its title on the alert element; ids on
        // inner Text views do NOT enter the accessibility tree.
        let successAlert = app.alerts["已保存到通讯录"]
        XCTAssertTrue(
            successAlert.waitForExistence(timeout: timeout),
            "The export success surface must appear after a real/fake allowed write."
        )
        XCTAssertTrue(alertButton(app, "contact-export-success-ok").exists)
    }

    @MainActor
    private func assertDeniedSurface(_ app: XCUIApplication) {
        let deniedAlert = app.alerts["无法保存名片到通讯录"]
        XCTAssertTrue(
            deniedAlert.waitForExistence(timeout: 5),
            "The denied surface (REF-export-02 wording) must appear."
        )
        XCTAssertTrue(alertButton(app, "contact-export-settings").exists)
        XCTAssertTrue(alertButton(app, "contact-export-denied-cancel").exists)
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
