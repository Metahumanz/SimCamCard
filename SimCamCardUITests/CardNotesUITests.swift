//
//  CardNotesUITests.swift
//  SimCamCardUITests
//
//  P10 Notes user-workflow UI tests (Week 4 Increment 10).
//
//  Spec sources:
//   - spec/page-inventory.md P10 Notes ("View/add notes/history")
//   - spec/state-inventory.md S08 historyVisible / addingNote
//   - spec/reference-tests.md T18 (notes survive relaunch — the full
//     terminate/relaunch leg is CardPersistenceUITests)
//   - Evidence: evidence/screenshots/REF-notes-01-page.png
//
//  Fixture: launch argument `-SimCamCardFixture populated` seeds
//  MockBusinessCards.all over EPHEMERAL storage; card 001 starts with
//  notes: []. The pushed Notes page is therefore a real empty history.
//
//  Cases:
//   1. Add → save: Detail → 备注 → empty history → 新增备注 → type
//      跟进客户 → 保存 → the row appears immediately; pop to Detail and
//      reopen Notes — the note is still there (the single BusinessCard
//      aggregate was saved through the repository, not a View-local
//      copy).
//   2. Cancel: add 不会保存 → 取消 → no row; after pop/reopen the
//      history is still empty (cancel persists nothing).
//
//  Chinese IME quirk (same class as W4I9 group alert): with the
//  software keyboard visible, the first tap outside a focused Chinese
//  field can be consumed committing marked text instead of activating
//  the button. Unlike the single-line alert field, this multiline
//  TextEditor must NEVER be sent "\n" (that inserts a real newline
//  into the note) — so Save is tapped, then tapped once more only if
//  the editor is still on screen.
//

import XCTest

final class CardNotesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Fixture identifiers (mirror MockBusinessCards.swift)

    private let card001RowID = "card-row-00000000-0000-0000-0000-000000000001"

    private let savedNoteText = "跟进客户"
    private let cancelledNoteText = "不会保存"

    // MARK: - Case 1: add + save survives page leave/reopen

    @MainActor
    func testAddNoteSaveAndReopenShowsTheNote() throws {
        let app = launchPopulated()
        openCard001Notes(app)

        // Empty history (fixture card 001 seeds notes: []).
        let notesPage = app.descendants(matching: .any)["card-notes"]
        XCTAssertTrue(notesPage.waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.descendants(matching: .any)["card-notes-empty"].waitForExistence(timeout: 5),
            "The seeded card must open with an empty notes history."
        )
        XCTAssertFalse(app.staticTexts[savedNoteText].exists)

        attachScreenshot(app, name: "w4i10-notes-history")

        // Enter the inline add-note editor.
        app.buttons["card-notes-add"].tap()
        let editor = app.textViews["card-note-editor"]
        XCTAssertTrue(
            editor.waitForExistence(timeout: 5),
            "新增备注 should present the note editor."
        )

        editor.tap()
        editor.typeText(savedNoteText)

        tapSaveCommittingIME(app)

        // Back on the history: the note is visible immediately.
        XCTAssertTrue(
            app.descendants(matching: .any)["card-notes-history"].waitForExistence(timeout: 5),
            "Save should return to the notes history."
        )
        XCTAssertTrue(
            app.staticTexts[savedNoteText].waitForExistence(timeout: 5),
            "The saved note text must appear in the history immediately."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["card-notes-empty"].exists,
            "The empty state must disappear once a note exists."
        )
        attachScreenshot(app, name: "w4i10-note-added")

        // Pop to Detail, reopen Notes: still present — the note lives on
        // the saved BusinessCard aggregate, not on the pushed page.
        backToDetail(app)
        app.buttons["card-detail-notes"].tap()
        XCTAssertTrue(
            app.navigationBars["备注"].waitForExistence(timeout: 5),
            "Notes page should reopen from the Detail."
        )
        XCTAssertTrue(
            app.staticTexts[savedNoteText].waitForExistence(timeout: 5),
            "The saved note must still be present after leaving and reopening Notes."
        )
    }

    // MARK: - Case 2: add + cancel persists nothing

    @MainActor
    func testAddNoteCancelPersistsNothing() throws {
        let app = launchPopulated()
        openCard001Notes(app)

        app.buttons["card-notes-add"].tap()
        let editor = app.textViews["card-note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        editor.tap()
        editor.typeText(cancelledNoteText)
        app.buttons["card-note-cancel"].tap()

        // Editor discarded; history stays empty.
        XCTAssertTrue(
            app.descendants(matching: .any)["card-notes-history"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-notes-empty"].waitForExistence(timeout: 5),
            "Cancel must return to an empty history."
        )
        XCTAssertFalse(app.staticTexts[cancelledNoteText].exists)

        // Pop to Detail and reopen: cancel really persisted nothing.
        backToDetail(app)
        app.buttons["card-detail-notes"].tap()
        XCTAssertTrue(
            app.navigationBars["备注"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-notes-empty"].waitForExistence(timeout: 5),
            "The cancelled note must not appear after reopening Notes."
        )
        XCTAssertFalse(app.staticTexts[cancelledNoteText].exists)
    }

    // MARK: - Case 2b: More Actions sheet entry

    @MainActor
    func testMoreActionsSheetAlsoPushesNotesPage() throws {
        let app = launchPopulated()

        let row = app.descendants(matching: .any)[card001RowID].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.navigationBars["名片详情"].waitForExistence(timeout: 10))

        // REF-detail-04: the ••• more-actions sheet carries 备注.
        app.buttons["card-detail-more"].tap()
        // Resolve via firstMatch: during the dialog's present animation
        // the accessibility snapshot can momentarily rebuild sparse;
        // firstMatch re-resolves lazily at tap time instead of pinning
        // a stale snapshot.
        let sheetNotes = app.buttons.matching(identifier: "card-detail-more-notes").firstMatch
        XCTAssertTrue(sheetNotes.waitForExistence(timeout: 5))
        sheetNotes.tap()

        XCTAssertTrue(
            app.navigationBars["备注"].waitForExistence(timeout: 5),
            "The more-sheet 备注 entry must push the same Notes page."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-notes"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["card-notes-empty"].waitForExistence(timeout: 5)
        )
    }

    // MARK: - Helpers

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

    @MainActor
    private func openCard001Notes(_ app: XCUIApplication) {
        let row = app.descendants(matching: .any)[card001RowID].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Card 001 row should exist.")
        row.tap()
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 10),
            "Card Detail should open."
        )
        app.buttons["card-detail-notes"].tap()
        XCTAssertTrue(
            app.navigationBars["备注"].waitForExistence(timeout: 5),
            "备注 should push the Notes page."
        )
    }

    @MainActor
    private func backToDetail(_ app: XCUIApplication) {
        app.navigationBars["备注"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.navigationBars["名片详情"].waitForExistence(timeout: 5),
            "Back should return to Card Detail."
        )
    }

    /// Taps 保存, re-tapping once if the first tap was consumed by the
    /// Chinese IME committing marked text (editor still present). No
    /// newline is ever typed into the multiline TextEditor.
    @MainActor
    private func tapSaveCommittingIME(_ app: XCUIApplication) {
        let saveButton = app.buttons["card-note-save"]
        let editor = app.textViews["card-note-editor"]

        saveButton.tap()
        if editor.waitForExistence(timeout: 2) {
            // First tap committed IME marked text (or was dropped); retry.
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
}
