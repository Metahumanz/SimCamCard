//
//  CardGroupUITests.swift
//  SimCamCardUITests
//
//  T16 Group / Tag UI tests (XCTest).
//
//  Spec sources:
//   - spec/page-inventory.md P09 Group Management
//   - spec/state-inventory.md S07 Group / Tag
//   - spec/reference-tests.md T16 ("Create → Assign → View by Group/Tag
//     → Delete Group/Tag. Deleting a group removes the group while the
//     business cards remain in the Card Holder.")
//   - Evidence: evidence/screenshots/REF-group-01-select-card.png,
//     REF-group-02-create-dialog.png, REF-group-03-assigned.png,
//     REF-group-04-list.png, REF-group-05-filtered-list.png,
//     REF-group-06-delete-confirmation.png, REF-group-07-after-delete-empty.png
//
//  Fixture: launch argument `-SimCamCardFixture populated` seeds
//  MockBusinessCards.all (card001 张伟 full, card002 李娜, card004 张伟 minimal).
//
//  Cases:
//   1. Full flow: group entry → select card001 → create group "客户" →
//      group list shows 客户(1) → open group → filtered list shows card001
//      only → back to Holder → all 3 cards present.
//   2. Delete flow: create group → delete → confirmation → confirm →
//      group-empty visible → back to Holder → all 3 cards still exist.
//
//  Membership only — no row-position dependency; rows located by
//  fixed UUID identifiers.
//
//  Note on SwiftUI alerts: a `.alert` TextField is bridged to a
//  UIAlertController text field, which does NOT export a custom
//  accessibilityIdentifier (its placeholderValue is exposed instead).
//  Alert Buttons do export their identifiers. Tests therefore locate the
//  name field through `app.alerts["新建分组"].textFields` (placeholder
//  "请输入分组名称"), and buttons through their stable identifiers.
//

import XCTest

final class CardGroupUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Fixture identifiers

    private let card001RowID = "card-row-00000000-0000-0000-0000-000000000001"
    private let card002RowID = "card-row-00000000-0000-0000-0000-000000000002"
    private let card004RowID = "card-row-00000000-0000-0000-0000-000000000004"

    private let createAlertTitle = "新建分组"
    private let namePlaceholder = "请输入分组名称"
    private let deleteAlertTitle = "删除分组"

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

    /// Taps the group entry in the Holder toolbar and waits for the
    /// Group Management page.
    @MainActor
    private func openGroupManagement(app: XCUIApplication) {
        let groupsButton = app.buttons["card-holder-groups"]
        XCTAssertTrue(
            groupsButton.waitForExistence(timeout: 10),
            "Group entry button should exist."
        )
        groupsButton.tap()
        XCTAssertTrue(
            app.navigationBars["分组"].waitForExistence(timeout: 10),
            "Group Management should be pushed."
        )
    }

    /// In the group-list phase, taps the "新建分组" entry to enter the
    /// card-selection phase.
    @MainActor
    private func enterCardSelection(app: XCUIApplication) {
        let createEntry = app.descendants(matching: .any)["group-create"]
        XCTAssertTrue(
            createEntry.waitForExistence(timeout: 10),
            "新建分组 entry should exist."
        )
        createEntry.tap()
        // The list swaps to the card-selection phase (the group-list
        // tree is removed). Callers verify the phase by waiting for the
        // `group-card-select-*` rows.
    }

    /// Selects the given card in the card-selection list.
    @MainActor
    private func selectCard(_ rowID: String, app: XCUIApplication) {
        let row = app.descendants(matching: .any)[rowID]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Selection row \(rowID) should exist.")
        row.tap()
    }

    /// Taps the bottom "添加到分组 (N)" button in the card-selection
    /// phase. Located by its localized label prefix (NOT by the
    /// `group-create` identifier, which is shared with the group-list
    /// "新建分组" entry).
    @MainActor
    private func tapAddToGroup(app: XCUIApplication) {
        let addButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "添加到分组")
        ).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 10), "添加到分组 button should exist.")
        addButton.tap()
    }

    /// In the "新建分组" alert, types the group name into the alert text
    /// field (located by alert container + placeholder, since alert text
    /// fields do not export custom identifiers) and taps 完成.
    @MainActor
    private func nameGroupAndConfirm(_ name: String, app: XCUIApplication) {
        let alert = app.alerts[createAlertTitle]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Create-group alert should appear.")

        let nameField = alert.textFields.firstMatch
        XCTAssertTrue(
            nameField.waitForExistence(timeout: 5),
            "Alert should contain the group-name text field."
        )
        XCTAssertEqual(nameField.placeholderValue, namePlaceholder)
        nameField.tap()
        nameField.typeText(name)

        // `.firstMatch`: a SwiftUI alert action can surface its
        // accessibility identifier on more than one bridged node, so a
        // direct subscript query fails the single-match check on tap.
        let confirmButton = alert.buttons.matching(
            identifier: "group-create-confirm"
        ).firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), "完成 button should exist.")
        confirmButton.tap()
    }

    /// Clears the active group filter from the Holder banner.
    ///
    /// The banner container carries `group-filter-active`; its × control
    /// is labelled 清除分组筛选 and is given `group-filter-clear`.
    ///
    /// Bridging note (verified against an archived failure snapshot):
    /// when an `.accessibilityIdentifier` is attached to a container that
    /// also hosts an interactive Button, the SwiftUI → UIKit accessibility
    /// bridge surfaces that container identifier on the button's bridged
    /// node as well, so the button's own `group-filter-clear` identifier is
    /// not queryable while its accessibility label is intact. Locate by
    /// label first, identifier second, then a trailing-edge coordinate tap
    /// (the × is always at the banner's trailing edge).
    @MainActor
    private func clearGroupFilter(app: XCUIApplication) {
        let banner = app.descendants(matching: .any)["group-filter-active"]
        XCTAssertTrue(banner.waitForExistence(timeout: 10), "Group filter banner should exist.")

        let byLabel = app.buttons["清除分组筛选"]
        if byLabel.waitForExistence(timeout: 5) {
            byLabel.tap()
            return
        }

        let byID = app.buttons.matching(identifier: "group-filter-clear").firstMatch
        if byID.waitForExistence(timeout: 2) {
            byID.tap()
            return
        }

        // Neither query resolved a discrete button — keep a hierarchy
        // snapshot, then tap the trailing edge where the × is laid out.
        let treeAttachment = XCTAttachment(string: app.debugDescription)
        treeAttachment.name = "w4i7-filter-tree-fallback"
        treeAttachment.lifetime = .keepAlways
        add(treeAttachment)
        banner.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
    }

    /// Creates a group named `name` assigned to `cardIDs`, starting from
    /// the Group Management group-list phase.
    @MainActor
    private func createGroup(
        named name: String,
        withCardIDs cardIDs: [String],
        app: XCUIApplication
    ) {
        enterCardSelection(app: app)
        for cardID in cardIDs {
            selectCard(cardID, app: app)
        }
        XCTAssertTrue(
            app.staticTexts["已选 \(cardIDs.count) 张"].waitForExistence(timeout: 5),
            "Header should show 已选 \(cardIDs.count) 张."
        )
        tapAddToGroup(app: app)
        nameGroupAndConfirm(name, app: app)
    }

    // MARK: - T16 full flow

    @MainActor
    func testGroupFullFlow() throws {
        let app = launchPopulated()

        // 1. Open Group Management.
        openGroupManagement(app: app)

        // 2. Empty state visible (no groups yet).
        XCTAssertTrue(
            app.descendants(matching: .any)["group-empty"].waitForExistence(timeout: 10),
            "Empty group state should be visible."
        )

        // 3. New group → card selection → select card001.
        enterCardSelection(app: app)
        selectCard("group-card-select-00000000-0000-0000-0000-000000000001", app: app)
        XCTAssertTrue(
            app.staticTexts["已选 1 张"].waitForExistence(timeout: 5),
            "Header should show 已选 1 张."
        )

        // Screenshot: card selection (REF-group-01).
        let selectingShot = XCUIScreen.main.screenshot()
        let selectingAttachment = XCTAttachment(screenshot: selectingShot)
        selectingAttachment.name = "w4i7-group-selecting"
        selectingAttachment.lifetime = .keepAlways
        add(selectingAttachment)

        // 4. Tap 添加到分组 (1) → alert → name "客户" → confirm.
        tapAddToGroup(app: app)
        nameGroupAndConfirm("客户", app: app)

        // 5. Group list should show "客户" and "(1)".
        XCTAssertTrue(
            app.staticTexts["客户"].waitForExistence(timeout: 10),
            "Group name '客户' should appear in list."
        )
        XCTAssertTrue(
            app.staticTexts["(1)"].waitForExistence(timeout: 5),
            "Group count (1) should appear."
        )

        // Screenshot: group created (REF-group-03/04).
        let createdScreenshot = XCUIScreen.main.screenshot()
        let createdAttachment = XCTAttachment(screenshot: createdScreenshot)
        createdAttachment.name = "w4i7-group-created"
        createdAttachment.lifetime = .keepAlways
        add(createdAttachment)

        // 6. Tap the group name → Holder returns with filter active.
        app.staticTexts["客户"].tap()

        // 7. Verify filter banner shows 客户.
        XCTAssertTrue(
            app.descendants(matching: .any)["group-filter-active"].waitForExistence(timeout: 10),
            "Group filter banner should be active."
        )

        // 8. card001 visible, card002 and card004 absent in filtered list.
        XCTAssertTrue(
            app.descendants(matching: .any)[card001RowID].waitForExistence(timeout: 5),
            "Card 001 should be visible in filtered list."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)[card002RowID].exists,
            "Card 002 should NOT be visible in filtered list."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)[card004RowID].exists,
            "Card 004 should NOT be visible in filtered list."
        )

        // Screenshot: filtered list (REF-group-05).
        let filteredScreenshot = XCUIScreen.main.screenshot()
        let filteredAttachment = XCTAttachment(screenshot: filteredScreenshot)
        filteredAttachment.name = "w4i7-group-filtered"
        filteredAttachment.lifetime = .keepAlways
        add(filteredAttachment)

        // 9. Clear filter → all 3 cards restored.
        clearGroupFilter(app: app)

        XCTAssertTrue(
            app.descendants(matching: .any)[card001RowID].waitForExistence(timeout: 5),
            "Card 001 should be restored."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[card002RowID].waitForExistence(timeout: 5),
            "Card 002 should be restored."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[card004RowID].waitForExistence(timeout: 5),
            "Card 004 should be restored."
        )
    }

    // MARK: - T20 (E12) create-group cancel leaves everything unchanged

    /// T20 exception matrix E12: start the create-group flow, select a
    /// card and cancel at BOTH possible points — the card-selection
    /// toolbar 取消 and the naming-alert 取消. The group catalog must
    /// stay empty (no group created, no tag assigned). Tag/card
    /// immutability is additionally covered at the ViewModel level by
    /// the T16 unit suite; this is the direct UI proof of the cancels.
    @MainActor
    func testCreateGroupCancelLeavesCatalogAndCardsUnchanged() throws {
        let app = launchPopulated()
        openGroupManagement(app: app)

        XCTAssertTrue(
            app.descendants(matching: .any)["group-empty"].waitForExistence(timeout: 10),
            "Group catalog should start empty."
        )

        // 1. Selection phase → select card001 → toolbar 取消 returns to
        //    the group list without creating anything.
        enterCardSelection(app: app)
        selectCard("group-card-select-00000000-0000-0000-0000-000000000001", app: app)
        XCTAssertTrue(app.staticTexts["已选 1 张"].waitForExistence(timeout: 5))
        app.buttons["group-selection-cancel"].tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["group-management"].waitForExistence(timeout: 5),
            "Selection cancel must return to the group list."
        )
        XCTAssertTrue(app.descendants(matching: .any)["group-empty"].exists,
                      "Catalog must still be empty after selection cancel.")

        // 2. Selection phase again → alert → type a name → alert 取消.
        enterCardSelection(app: app)
        selectCard("group-card-select-00000000-0000-0000-0000-000000000001", app: app)
        tapAddToGroup(app: app)

        let alert = app.alerts[createAlertTitle]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Naming alert should appear.")
        let nameField = alert.textFields.firstMatch
        nameField.tap()
        nameField.typeText("临时客户")
        // `.firstMatch` by LABEL (no custom identifier on the cancel
        // action): a SwiftUI alert action can surface its bridge node
        // more than once, mirroring the documented 完成 button case.
        let cancelButton = alert.buttons.matching(
            NSPredicate(format: "label == %@", "取消")
        ).firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "取消 should exist in the alert.")
        cancelButton.tap()

        // Catalog stays empty — the typed name must not create a group.
        // Wait through the alert dismiss animation before asserting.
        var alertGone = false
        for _ in 0..<20 {
            if !alert.exists { alertGone = true; break }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }
        XCTAssertTrue(alertGone, "Cancel must dismiss the naming alert.")
        // The alert cancel returns to the CARD-SELECTION phase (no
        // group is created); the toolbar 取消 is what yields the list.
        let selectionRow = app.descendants(matching: .any)[
            "group-card-select-00000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(selectionRow.waitForExistence(timeout: 5),
                      "Alert cancel must return to the card-selection phase, not create a group.")
        app.buttons["group-selection-cancel"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["group-empty"].waitForExistence(timeout: 5),
            "Catalog must remain empty after the full cancel sequence."
        )
        XCTAssertFalse(app.staticTexts["临时客户"].exists,
                       "The cancelled group name must not appear in the catalog.")

        // 3. Back to Holder → all fixture cards still present, tags
        //    untouched (no group filter banner).
        app.navigationBars["分组"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Should return to the Card Holder."
        )
        XCTAssertFalse(app.descendants(matching: .any)["group-filter-active"].exists,
                       "No group assignment (and no filter) may result from cancels.")
        for rowID in [card001RowID, card002RowID, card004RowID] {
            XCTAssertTrue(app.descendants(matching: .any)[rowID].waitForExistence(timeout: 5),
                          "Card \(rowID) must still be present after cancels.")
        }
    }

    // MARK: - T16 delete flow

    @MainActor
    func testGroupDeleteFlow() throws {
        let app = launchPopulated()

        // 1. Create a group with card001, ending on the group list.
        openGroupManagement(app: app)
        createGroup(
            named: "客户",
            withCardIDs: ["group-card-select-00000000-0000-0000-0000-000000000001"],
            app: app
        )

        // Verify the group exists before deleting.
        XCTAssertTrue(
            app.staticTexts["客户"].waitForExistence(timeout: 10),
            "Group '客户' should exist before delete."
        )

        // 2. Tap the row delete button via its stable identifier prefix
        //    (its UUID is created at runtime; its label is "删除 客户").
        let deleteButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "group-delete-")
        ).firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 10), "Delete button should exist.")
        deleteButton.tap()

        // 3. Confirmation dialog.
        let deleteAlert = app.alerts[deleteAlertTitle]
        XCTAssertTrue(deleteAlert.waitForExistence(timeout: 10), "Delete confirmation alert should appear.")
        XCTAssertTrue(
            app.staticTexts["删除后分组不可恢复，名片将保留在名片夹。确认删除？"].waitForExistence(timeout: 5),
            "Delete confirmation message should appear."
        )

        // Screenshot: delete confirmation (REF-group-06).
        let confirmScreenshot = XCUIScreen.main.screenshot()
        let confirmAttachment = XCTAttachment(screenshot: confirmScreenshot)
        confirmAttachment.name = "w4i7-group-delete-confirm"
        confirmAttachment.lifetime = .keepAlways
        add(confirmAttachment)

        // 4. Confirm delete.
        let confirmDeleteButton = deleteAlert.buttons.matching(
            identifier: "group-delete-confirm"
        ).firstMatch
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5), "确认删除 button should exist.")
        confirmDeleteButton.tap()

        // 5. Empty state visible.
        XCTAssertTrue(
            app.descendants(matching: .any)["group-empty"].waitForExistence(timeout: 10),
            "Empty group state should be visible after delete."
        )

        // Screenshot: after delete empty (REF-group-07).
        let emptyScreenshot = XCUIScreen.main.screenshot()
        let emptyAttachment = XCTAttachment(screenshot: emptyScreenshot)
        emptyAttachment.name = "w4i7-group-after-delete"
        emptyAttachment.lifetime = .keepAlways
        add(emptyAttachment)

        // 6. Back to Holder → all 3 cards still exist.
        app.navigationBars["分组"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.navigationBars["名片夹"].waitForExistence(timeout: 10),
            "Should return to Card Holder."
        )

        XCTAssertTrue(
            app.descendants(matching: .any)[card001RowID].waitForExistence(timeout: 5),
            "Card 001 should still exist."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[card002RowID].waitForExistence(timeout: 5),
            "Card 002 should still exist."
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[card004RowID].waitForExistence(timeout: 5),
            "Card 004 should still exist."
        )
    }
}
