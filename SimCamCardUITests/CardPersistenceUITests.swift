//
//  CardPersistenceUITests.swift
//  SimCamCardUITests
//
//  T18 Persistence end-to-end UI test (Week 4 Increment 9), extended in
//  Week 4 Increment 10 to also prove the P10 user note survives a full
//  terminate/relaunch.
//
//  Spec sources:
//   - spec/reference-tests.md T18: "After a full quit and relaunch,
//     the saved card and retained edited data remain available. The
//     termination action itself has no useful screenshot; the
//     post-relaunch state is preserved as evidence."
//   - spec/state-inventory.md S10: savedBeforeQuit /
//     restoredAfterRelaunch; preserve original image, processed image,
//     corrected fields, group/tag, notes.
//   - spec/page-inventory.md P10 Notes (W4I10 user-workflow proof).
//
//  Proof model:
//   - LAUNCH 1: real File repositories under the isolated DEBUG
//     namespace `w4i9-t18-persistence` with reset:true. Through the
//     fixture-driven scanner (authorized camera / auto crop / success
//     OCR) capture → confirm → save ONE card; then correct its job
//     title via the saved-card Edit flow (T14); then create group
//     客户 and assign the card (T16); then open the P10 Notes page
//     and add the user note 跟进客户. The store now holds card +
//     corrected fields + group/tag + user note + original/processed
//     image bytes.
//   - XCUIApplication.terminate() and wait for the process to
//     actually reach .notRunning (a still-live process would prove
//     nothing about disk persistence).
//   - LAUNCH 2: a BRAND-NEW XCUIApplication with the SAME namespace
//     and reset:FALSE (must not wipe) and NO camera arguments. The app
//     builds brand-new File repositories from disk. Assertions verify
//     the card, corrected title, group catalog/membership, the user
//     note and the resolved card image all survived the full
//     terminate/relaunch.
//
//  NON-CLAIMS:
//   - Fixture-driven: DEBUG fakes drive camera/crop/OCR; this is not
//     real camera/Vision verification (unchanged from W3/W4 tests).
//   - Evidence screenshots are taken ONLY after the second launch
//     (plus the pre-terminate note workflow asserts no screenshot).
//

import XCTest

final class CardPersistenceUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Fixed scenario constants

    private let namespace = "w4i9-t18-persistence"

    private let cardName = "张伟"
    private let cardCompany = "上海智云科技有限公司"
    private let originalTitle = "产品总监 | Product Director"
    private let correctedTitle = "高级产品总监 | Senior Product Director"
    private let mobile = "+86 138 0013 8000"
    private let office = "+86 21 5555 1234"
    private let email = "wei.zhang@zhiyuntech.com"
    private let website = "www.zhiyuntech.com"
    private let groupName = "客户"

    /// P10 user note added before termination (W4I10 extension).
    private let noteText = "跟进客户"

    private let createAlertTitle = "新建分组"
    private let namePlaceholder = "请输入分组名称"

    // MARK: - Test

    @MainActor
    func testSavedCardEditGroupAndNoteSurviveFullTerminateAndRelaunch() throws {
        // ============ LAUNCH 1: write the full state ============
        let app = UITestAppFactory.launchPersistent(
            namespace: namespace,
            reset: true,
            arguments: [
                "-SimCamCardCamera", "authorized",
                "-SimCamCardCrop", "auto",
                "-SimCamCardOCR", "success",
            ]
        )

        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Card Holder should be visible after launch."
        )

        // 1. Scanner → capture → crop confirm → structured recognition.
        app.buttons["scan-entry"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-entry-view"].waitForExistence(timeout: 10),
            "Scanner should open."
        )
        app.buttons["scan-capture"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-crop-view"].waitForExistence(timeout: 10),
            "Shutter should enter the crop page."
        )
        app.buttons["scan-crop-confirm"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-recognition-form"].waitForExistence(timeout: 10),
            "Crop confirm should enter the structured recognition form."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-recognition-structured"].waitForExistence(timeout: 10),
            "Success fixture should settle in structuredResultAvailable."
        )

        // 2. Enter manual editing (Save lives in that state) and save
        //    WITHOUT altering the extracted fields — the T14 title
        //    correction happens afterward on the SAVED card.
        app.buttons["scan-recognition-edit"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["scan-recognition-manual-editing"].waitForExistence(timeout: 5),
            "编辑 should enter manual editing."
        )
        XCTAssertTrue(
            app.textFields["scan-edit-name"].waitForExistence(timeout: 5)
        )
        app.buttons["scan-recognition-save"].tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["scan-save-success"].waitForExistence(timeout: 10),
            "保存 should reach the P06 success state."
        )
        app.buttons["scan-save-done"].tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "完成 should pop back to the Holder."
        )
        let holderName = app.staticTexts[cardName]
        XCTAssertTrue(holderName.waitForExistence(timeout: 10),
                      "The saved card must appear in the Holder.")

        // 3. Open the saved card Detail and correct the job title via
        //    the existing-card Edit flow (T14).
        holderName.tap()
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 10),
            "Saved card Detail should open."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-job-title"].waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            app.descendants(matching: .any)["card-detail-job-title"].label,
            originalTitle,
            "Precondition: the saved card starts with the extracted title."
        )

        app.buttons["card-detail-edit"].tap()
        XCTAssertTrue(
            app.navigationBars["编辑名片"].waitForExistence(timeout: 5),
            "编辑 should present the 编辑名片 page."
        )
        let titleField = app.textFields["card-edit-job-title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        let clearButton = app.buttons["清除"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 3))
        clearButton.tap()
        titleField.typeText(correctedTitle)
        XCTAssertEqual(titleField.value as? String, correctedTitle)
        app.buttons["card-edit-save"].tap()

        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 5),
            "Edit save should return to the Card Detail."
        )
        XCTAssertEqual(
            app.descendants(matching: .any)["card-detail-job-title"].label,
            correctedTitle,
            "The Detail must show the corrected title."
        )

        // 3b. B-02 original-image E2E (BEFORE terminate): the just-saved
        //     card's Detail must show the original-image thumbnail; tapping
        //     it opens the full-screen viewer, which dismisses back to the
        //     Detail. This exercises the real saved bytes, not a fixture
        //     placeholder.
        let originalThumb = app.descendants(matching: .any)["card-detail-original-image"]
        XCTAssertTrue(
            originalThumb.waitForExistence(timeout: 5),
            "The saved card's Detail must show the original-image thumbnail before termination."
        )
        originalThumb.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-original-image-fullscreen"]
                .waitForExistence(timeout: 5),
            "Tapping the thumbnail must open the full-screen original-image viewer."
        )
        attachScreenshot(app, name: "w4i13-b02-original-image-fullscreen-before-relaunch")
        app.buttons["card-detail-image-close"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["card-detail-original-image-fullscreen"]
                .waitForNonExistence(timeout: 5),
            "Dismissing the viewer must return to the Detail."
        )

        // 4. Back to Holder → Group Management → create 客户 with the
        //    saved card assigned (T16). The card has a runtime UUID, so
        //    the selection row is located by its stable id prefix.
        app.navigationBars["名片详情"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Back should return to the Holder."
        )

        app.buttons["card-holder-groups"].tap()
        XCTAssertTrue(
            app.navigationBars["分组"].waitForExistence(timeout: 10),
            "Group Management should open."
        )
        app.descendants(matching: .any)["group-create"].tap()

        let selectionRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "group-card-select-"))
            .firstMatch
        XCTAssertTrue(selectionRow.waitForExistence(timeout: 10),
                      "The card-selection row for the saved card should exist.")
        selectionRow.tap()
        XCTAssertTrue(
            app.staticTexts["已选 1 张"].waitForExistence(timeout: 5),
            "Header should show 已选 1 张."
        )
        app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "添加到分组")
        ).firstMatch.tap()

        let alert = app.alerts[createAlertTitle]
        XCTAssertTrue(alert.waitForExistence(timeout: 10),
                      "Create-group alert should appear.")
        let alertNameField = alert.textFields.firstMatch
        XCTAssertTrue(alertNameField.waitForExistence(timeout: 5))
        XCTAssertEqual(alertNameField.placeholderValue, namePlaceholder)
        alertNameField.tap()
        alertNameField.typeText(groupName)
        confirmGroupCreateAlert(app: app, alert: alert, nameField: alertNameField)

        // Catalog now has 客户 with exactly one assigned card; this also
        // proves the card's tag collection was saved before quit.
        XCTAssertTrue(
            app.staticTexts[groupName].waitForExistence(timeout: 10),
            "Group 客户 should appear in the catalog."
        )
        XCTAssertTrue(
            app.staticTexts["(1)"].waitForExistence(timeout: 5),
            "Group 客户 should show member count (1)."
        )

        // 5. P10: back to the Holder → open the saved card's Detail →
        //    Notes → add a user note (W4I10). This exercises the real
        //    user workflow against the same File repository the group
        //    assignment just used.
        app.navigationBars["分组"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Back should return to the Holder before adding the note."
        )
        app.staticTexts[cardName].tap()
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 10),
            "Saved card Detail should open for the note step."
        )
        app.buttons["card-detail-notes"].tap()
        XCTAssertTrue(
            app.navigationBars["备注"].waitForExistence(timeout: 5),
            "备注 should push the Notes page."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-notes-empty"].waitForExistence(timeout: 5),
            "A freshly saved card starts with an empty notes history."
        )
        let noteAddButton = app.buttons["card-notes-add"]
        XCTAssertTrue(
            noteAddButton.waitForExistence(timeout: 5),
            "The Notes page should show the 新增备注 entry."
        )
        noteAddButton.tap()
        let noteEditor = app.textViews["card-note-editor"]
        XCTAssertTrue(noteEditor.waitForExistence(timeout: 5))
        noteEditor.tap()
        noteEditor.typeText(noteText)
        tapNoteSaveCommittingIME(app)
        XCTAssertTrue(
            app.staticTexts[noteText].waitForExistence(timeout: 5),
            "The user note must be visible in the history before termination."
        )

        // ============ FULL TERMINATION ============
        app.terminate()
        XCTAssertTrue(
            app.wait(for: .notRunning, timeout: 15),
            "The app must fully terminate before the relaunch leg."
        )

        // ============ LAUNCH 2: restore from disk (reset: false) ============
        let relaunched = UITestAppFactory.launchPersistent(
            namespace: namespace,
            reset: false
        )

        XCTAssertTrue(
            relaunched.navigationBars["名片夹"].waitForExistence(timeout: 15),
            "Relaunched app should reach the Card Holder."
        )
        XCTAssertFalse(
            relaunched.descendants(matching: .any)["card-holder-empty"].waitForExistence(timeout: 3),
            "The Holder must not be empty after relaunch."
        )
        XCTAssertTrue(
            relaunched.staticTexts[cardName].waitForExistence(timeout: 10),
            "The saved card name must survive relaunch."
        )

        // Corrected field survives on the holder row secondary line.
        let savedRow = relaunched.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "card-row-"))
            .firstMatch
        XCTAssertTrue(savedRow.waitForExistence(timeout: 10))
        XCTAssertTrue(
            savedRow.staticTexts
                .matching(NSPredicate(format: "label CONTAINS %@", correctedTitle))
                .firstMatch
                .waitForExistence(timeout: 5),
            "The holder row must show the corrected title after relaunch."
        )

        // Processed image bytes restore: the thumbnail resolves to a
        // real image rather than the no-asset placeholder.
        XCTAssertTrue(
            relaunched.descendants(matching: .any)["card-row-thumbnail"]
                .waitForExistence(timeout: 10),
            "The processed image must resolve from disk after relaunch."
        )

        // Evidence 1: Holder after relaunch.
        attachScreenshot(
            relaunched,
            name: "w4i9-persistence-holder-after-relaunch"
        )

        // Detail after relaunch: corrected title + all structured fields.
        relaunched.staticTexts[cardName].tap()
        XCTAssertTrue(
            relaunched.navigationBars["名片详情"].waitForExistence(timeout: 10),
            "The saved card Detail should open after relaunch."
        )
        XCTAssertEqual(
            relaunched.descendants(matching: .any)["card-detail-name"].label,
            cardName
        )
        XCTAssertEqual(
            relaunched.descendants(matching: .any)["card-detail-job-title"].label,
            correctedTitle,
            "The corrected title must be present on the relaunched Detail."
        )
        XCTAssertTrue(relaunched.staticTexts[cardCompany].exists)
        XCTAssertTrue(relaunched.staticTexts[mobile].exists)
        XCTAssertTrue(relaunched.staticTexts[office].exists)
        XCTAssertTrue(relaunched.staticTexts[email].exists)

        // B-02 original-image E2E (AFTER relaunch): the restored original
        // bytes must again render as a tappable thumbnail that opens the
        // full-screen viewer and dismisses back to the Detail — proving the
        // original asset survived the full terminate/relaunch, not just the
        // processed thumbnail.
        let restoredThumb = relaunched.descendants(matching: .any)["card-detail-original-image"]
        XCTAssertTrue(
            restoredThumb.waitForExistence(timeout: 5),
            "The original-image thumbnail must survive the full terminate/relaunch."
        )
        restoredThumb.tap()
        XCTAssertTrue(
            relaunched.descendants(matching: .any)["card-detail-original-image-fullscreen"]
                .waitForExistence(timeout: 5),
            "Tapping the restored thumbnail must open the full-screen viewer."
        )
        attachScreenshot(relaunched, name: "w4i13-b02-original-image-fullscreen-after-relaunch")
        relaunched.buttons["card-detail-image-close"].tap()
        XCTAssertTrue(
            relaunched.descendants(matching: .any)["card-detail-original-image-fullscreen"]
                .waitForNonExistence(timeout: 5),
            "Dismissing the restored viewer must return to the Detail."
        )

        // B-02: the original-image section appears on a saved card with
        // stored bytes and can push the website row below the fold.
        // Scroll down before asserting the last field row.
        relaunched.swipeUp()
        XCTAssertTrue(relaunched.staticTexts[website].exists)

        // Evidence 2: Detail after relaunch.
        attachScreenshot(
            relaunched,
            name: "w4i9-persistence-detail-after-relaunch"
        )

        // P10 note after relaunch: Detail → Notes shows the user note
        // that was added immediately before terminate (W4I10 upgrade
        // of T18 — real add → terminate → relaunch persistence).
        relaunched.buttons["card-detail-notes"].tap()
        XCTAssertTrue(
            relaunched.navigationBars["备注"].waitForExistence(timeout: 5),
            "The Notes page should open after relaunch."
        )
        XCTAssertTrue(
            relaunched.staticTexts[noteText].waitForExistence(timeout: 5),
            "The user note 跟进客户 must survive the full terminate/relaunch."
        )
        XCTAssertFalse(
            relaunched.descendants(matching: .any)["card-notes-empty"].exists,
            "The restored history must not show the empty state."
        )

        // Evidence 3 (W4I10): the restored note, taken AFTER the
        // second launch.
        attachScreenshot(
            relaunched,
            name: "w4i10-note-after-relaunch"
        )

        relaunched.navigationBars["备注"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            relaunched.navigationBars["名片详情"].waitForExistence(timeout: 5)
        )

        // Group catalog after relaunch: 客户 still exists, count 1.
        relaunched.navigationBars["名片详情"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            relaunched.navigationBars["名片夹"].waitForExistence(timeout: 10)
        )
        relaunched.buttons["card-holder-groups"].tap()
        XCTAssertTrue(
            relaunched.navigationBars["分组"].waitForExistence(timeout: 10),
            "Group Management should open after relaunch."
        )
        XCTAssertTrue(
            relaunched.staticTexts[groupName].waitForExistence(timeout: 10),
            "The 客户 group catalog entry must survive relaunch."
        )
        XCTAssertTrue(
            relaunched.staticTexts["(1)"].waitForExistence(timeout: 5),
            "The group must still show one assigned card after relaunch."
        )

        // Evidence 3: Group management after relaunch.
        attachScreenshot(
            relaunched,
            name: "w4i9-persistence-group-after-relaunch"
        )

        // Filtering by the restored group shows the restored card and
        // its restored image.
        relaunched.staticTexts[groupName].tap()
        XCTAssertTrue(
            relaunched.descendants(matching: .any)["group-filter-active"]
                .waitForExistence(timeout: 10),
            "Tapping the restored group should activate its filter."
        )
        XCTAssertTrue(
            relaunched.staticTexts[cardName].waitForExistence(timeout: 5),
            "The saved card should appear in the restored group filter."
        )
        XCTAssertTrue(
            relaunched.descendants(matching: .any)["card-row-thumbnail"]
                .waitForExistence(timeout: 10),
            "The card image should be present in the filtered list."
        )
    }

    // MARK: - Helpers

    /// Taps the note editor 保存 button, re-tapping once if the first
    /// tap was consumed by the Chinese IME committing marked text.
    ///
    /// Same software-keyboard quirk as `confirmGroupCreateAlert`, but for
    /// a MULTILINE TextEditor a Return keystroke must never be faked
    /// (it would insert a literal newline into the note) — the remedy
    /// here is purely a guarded second tap.
    @MainActor
    private func tapNoteSaveCommittingIME(_ app: XCUIApplication) {
        let saveButton = app.buttons["card-note-save"]
        let editor = app.textViews["card-note-editor"]

        saveButton.tap()
        if editor.waitForExistence(timeout: 2) {
            saveButton.tap()
        }
        XCTAssertTrue(
            editor.waitForNonExistence(timeout: 5),
            "保存 should leave the note editor after the committed second tap."
        )
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Commits the alert TextField input and reliably taps 完成.
    ///
    /// With the software keyboard visible, the Chinese IME candidate
    /// session can swallow the first tap outside the keyboard (it is
    /// consumed to commit marked text / resign first responder),
    /// leaving the 新建分组 alert on screen without firing 完成.
    /// Commit with the keyboard Return key first, then re-resolve the
    /// alert button (the alert re-centers once the keyboard dismisses),
    /// tap it, and verify the alert actually disappeared with one
    /// guarded retry.
    @MainActor
    private func confirmGroupCreateAlert(
        app: XCUIApplication,
        alert: XCUIElement,
        nameField: XCUIElement
    ) {
        let confirmID = "group-create-confirm"

        // Send Return into the field directly (no keyboard-node query):
        // it commits any pending Chinese IME marked text and ends editing
        // on a single-line alert field. In the UIAlertController-hosted
        // field it may also activate the default action — both outcomes
        // are handled below.
        nameField.typeText("\n")

        for _ in 0..<2 {
            // A previous activation may already have dismissed the alert.
            guard alert.waitForExistence(timeout: 3) else { return }
            let confirm = alert.buttons.matching(identifier: confirmID).firstMatch
            guard confirm.waitForExistence(timeout: 3) else { continue }
            confirm.tap()
            if alert.waitForNonExistence(timeout: 4) { return }
            // Still present: the previous activation was consumed by the
            // keyboard/IME; settle briefly, then re-activate 完成.
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertFalse(alert.exists, "新建分组 alert should dismiss after tapping 完成.")
    }
}
