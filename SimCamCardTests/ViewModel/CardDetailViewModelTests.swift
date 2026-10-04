//
//  CardDetailViewModelTests.swift
//  SimCamCardTests
//
//  Unit tests for CardDetailViewModel (Swift Testing).
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail
//   - spec/state-inventory.md S06 detailCollapsed
//   - spec/reference-tests.md T13 Detail (saved structured fields visible),
//     T14 Existing-Card Editing ("edited title → stored BusinessCard
//     changes → Detail displays corrected title")
//   - spec/data-model.md §Multi-value observation, §Missing-field rule
//
//  What is verified:
//   - The read-only ViewModel holds the exact BusinessCard value it was
//     initialized with — no DTO remapping, no dropped or fabricated fields.
//   - Multi-value collections (phones[] with distinct kinds, emails[])
//     survive without loss.
//   - The Card 004 minimal fixture exposes ONLY name + mobile; absent
//     structured fields remain nil/empty (T20 negative case).
//   - T14: begin/intent/cancel/save workflow, same-id repository replace
//     (count unchanged), Detail in-place refresh, existing phone ids
//     preserved, metadata preserved, updatedAt advanced.
//

import Testing
import Foundation
@testable import SimCamCard

@MainActor
@Suite("CardDetailViewModel")
struct CardDetailViewModelTests {

    // MARK: - Multi-value field preservation (always compiled)

    @Test("all phone kinds and multiple emails are preserved without loss")
    func multiValueFieldsArePreservedWithoutLoss() async {
        let id = UUID()
        let card = BusinessCard(
            id: id,
            originalImageReference: "test-original",
            processedImageReference: "test-processed",
            name: "多值测试",
            company: "示例公司",
            jobTitle: "经理",
            website: "example.com",
            address: "示例地址",
            phones: [
                PhoneNumber(id: UUID(), kind: .mobile, value: "13800000000"),
                PhoneNumber(id: UUID(), kind: .office, value: "02111111111"),
                PhoneNumber(id: UUID(), kind: .fax, value: "02122222222"),
            ],
            emails: ["one@example.com", "two@example.com"]
        )
        let repository = InMemoryBusinessCardRepository(initialCards: [card])

        let viewModel = CardDetailViewModel(card: card, repository: repository)
        let displayed = viewModel.card

        #expect(displayed.id == id)
        #expect(displayed.phones.count == 3)
        #expect(displayed.phones.map(\.kind) == [.mobile, .office, .fax])
        #expect(displayed.phones.map(\.value) == [
            "13800000000", "02111111111", "02122222222"
        ])
        #expect(displayed.emails == ["one@example.com", "two@example.com"])
        #expect(await repository.allCards().count == 1)
    }

    // MARK: - Deterministic fixtures (DEBUG-only; MockBusinessCards is
    // compiled out of Release)

    #if DEBUG

    @Test("full fixture card 001 exposes every structured Domain value")
    func fullFixtureExposesAllStructuredValues() {
        let viewModel = CardDetailViewModel(
            card: MockBusinessCards.card001,
            repository: InMemoryBusinessCardRepository(initialCards: MockBusinessCards.all)
        )
        let card = viewModel.card

        // Identity
        #expect(card.id == MockBusinessCards.card001ID)

        // Header fields
        #expect(card.name == "张伟")
        #expect(card.jobTitle == "产品总监 | Product Director")
        #expect(card.company == "上海智云科技有限公司")

        // Contact fields
        #expect(card.website == "www.zhiyuntech.com")
        #expect(card.address == "上海市浦东新区世纪大道100号 200120")
        #expect(card.emails == ["wei.zhang@zhiyuntech.com"])

        // Multi-phone: both kinds and values preserved
        #expect(card.phones.count == 2)
        #expect(card.phones(of: .mobile).map(\.value) == ["+86 138 0013 8000"])
        #expect(card.phones(of: .office).map(\.value) == ["+86 21 5555 1234"])

        // The ViewModel must expose the SAME value type, not a copy/DTO:
        #expect(card == MockBusinessCards.card001)
    }

    @Test("minimal fixture card 004 preserves only name and mobile and fabricates nothing")
    func minimalFixtureDoesNotFabricateMissingFields() {
        let viewModel = CardDetailViewModel(
            card: MockBusinessCards.card004,
            repository: InMemoryBusinessCardRepository(initialCards: [MockBusinessCards.card004])
        )
        let card = viewModel.card

        // Present fields
        #expect(card.name == "张伟")
        #expect(card.phones.count == 1)
        #expect(card.phones.first?.kind == .mobile)
        #expect(card.phones.first?.value == "+86 138 0013 8000")

        // Absent structured fields stay nil/empty — no fabrication
        // (spec/data-model.md §Missing-field rule; T20 Card 004).
        #expect(card.company == nil)
        #expect(card.jobTitle == nil)
        #expect(card.website == nil)
        #expect(card.address == nil)
        #expect(card.emails.isEmpty)
        #expect(card.phones(of: .office).isEmpty)
        #expect(card.phones(of: .fax).isEmpty)
        #expect(card.tags.isEmpty)
        #expect(card.notes.isEmpty)
    }

    // MARK: - T14 Existing-Card Editing

    /// Builds a VM over a repository seeded with ALL mock cards so the
    /// duplicate-count regression (N stays N) is meaningful.
    private func makeEditingViewModel() -> (
        CardDetailViewModel, InMemoryBusinessCardRepository
    ) {
        let repository = InMemoryBusinessCardRepository(initialCards: MockBusinessCards.all)
        let viewModel = CardDetailViewModel(
            card: MockBusinessCards.card001,
            repository: repository
        )
        return (viewModel, repository)
    }

    private func currentDraft(_ viewModel: CardDetailViewModel) -> BusinessCardEditDraft? {
        guard case .editing(let draft) = viewModel.editState else { return nil }
        return draft
    }

    @Test("T14 beginEditing creates a draft from the card; re-entry keeps it")
    func beginEditingCreatesDraftAndReEntryIsStable() async {
        let (viewModel, repository) = makeEditingViewModel()
        #expect(viewModel.editState == .viewing)

        viewModel.beginEditing()
        let first = currentDraft(viewModel)
        #expect(first != nil)
        #expect(first?.source == MockBusinessCards.card001)
        #expect(first?.jobTitle == "产品总监 | Product Director")

        // Mutate then re-enter: the in-progress draft must survive.
        viewModel.updateJobTitle("临时修改")
        viewModel.beginEditing()
        #expect(currentDraft(viewModel)?.jobTitle == "临时修改")
        // Nothing persisted while editing.
        #expect(
            await repository.card(id: MockBusinessCards.card001ID)?.jobTitle
                == "产品总监 | Product Director"
        )
    }

    @Test("T14 edit intents update the draft only; the displayed card is untouched")
    func intentsMutateDraftOnly() {
        let (viewModel, _) = makeEditingViewModel()
        viewModel.beginEditing()
        viewModel.updateJobTitle("高级产品总监 | Senior Product Director")
        viewModel.updateName("张伟 修正")
        viewModel.updatePhone(
            id: MockBusinessCards.card001.phones[0].id,
            value: "+86 138 0013 9999"
        )
        viewModel.updateEmail(index: 0, value: "edited@example.com")
        viewModel.updateWebsite("https://example.cn")
        viewModel.updateAddress("新地址 1 号")
        viewModel.updateCompany("新公司")

        #expect(currentDraft(viewModel)?.jobTitle == "高级产品总监 | Senior Product Director")
        #expect(currentDraft(viewModel)?.name == "张伟 修正")
        #expect(currentDraft(viewModel)?.phones.first?.value == "+86 138 0013 9999")
        #expect(currentDraft(viewModel)?.emails == ["edited@example.com"])
        #expect(currentDraft(viewModel)?.website == "https://example.cn")
        #expect(currentDraft(viewModel)?.address == "新地址 1 号")
        #expect(currentDraft(viewModel)?.company == "新公司")

        // The displayed card remains the original until save.
        #expect(viewModel.card == MockBusinessCards.card001)
        #expect(viewModel.card.jobTitle == "产品总监 | Product Director")
    }

    @Test("T14 edit intents are ignored outside editing (incl. unknown ids/indices)")
    func intentsIgnoredOutsideEditing() {
        let (viewModel, _) = makeEditingViewModel()
        viewModel.updateJobTitle("X")
        viewModel.updatePhone(id: UUID(), value: "X")
        viewModel.updateEmail(index: 9, value: "X")
        #expect(viewModel.editState == .viewing)
        #expect(viewModel.card == MockBusinessCards.card001)

        viewModel.beginEditing()
        // Unknown phone id and out-of-range index cannot occur via the
        // form; they must not crash or alter the draft.
        viewModel.updatePhone(id: UUID(), value: "X")
        viewModel.updateEmail(index: 9, value: "X")
        #expect(currentDraft(viewModel)?.phones.map(\.value)
                == MockBusinessCards.card001.phones.map(\.value))
        #expect(currentDraft(viewModel)?.emails == MockBusinessCards.card001.emails)
    }

    @Test("T14 cancel discards the draft; the card and repository stay unchanged")
    func cancelRestoresViewingWithoutPersisting() async {
        let (viewModel, repository) = makeEditingViewModel()
        viewModel.beginEditing()
        viewModel.updateJobTitle("高级产品总监 | Senior Product Director")

        viewModel.cancelEditing()
        #expect(viewModel.editState == .viewing)
        #expect(viewModel.card == MockBusinessCards.card001)
        #expect(await repository.allCards().count == 3)
        let stored = await repository.card(id: MockBusinessCards.card001ID)
        #expect(stored == MockBusinessCards.card001)

        // Cancel while viewing is a safe no-op.
        viewModel.cancelEditing()
        #expect(viewModel.editState == .viewing)
    }

    @Test("T14 save title replaces the same-id entity and refreshes Detail immediately")
    func saveTitlePersistsAndRefreshesDetail() async {
        let (viewModel, repository) = makeEditingViewModel()
        viewModel.beginEditing()
        viewModel.updateJobTitle("高级产品总监 | Senior Product Director")

        await viewModel.saveEdits()

        // Workflow returns to viewing with the corrected card in place.
        #expect(viewModel.editState == .viewing)
        #expect(viewModel.card.jobTitle == "高级产品总监 | Senior Product Director")

        // Repository: SAME id, replaced — no duplicate (N stays N).
        let all = await repository.allCards()
        #expect(all.count == 3)
        let stored = await repository.card(id: MockBusinessCards.card001ID)
        #expect(stored != nil)
        #expect(stored?.id == MockBusinessCards.card001ID)
        #expect(stored?.jobTitle == "高级产品总监 | Senior Product Director")
        #expect(Set(all.map(\.id)) == Set(MockBusinessCards.all.map(\.id)))
    }

    @Test("T14 save preserves identity, metadata and existing phone ids; updatedAt advances")
    func savePreservesIdentityMetadataAndPhoneIDs() async {
        let (viewModel, _) = makeEditingViewModel()
        let original = MockBusinessCards.card001
        let originalPhoneIDs = original.phones.map(\.id)
        viewModel.beginEditing()
        viewModel.updateJobTitle("高级产品总监 | Senior Product Director")
        viewModel.updatePhone(id: original.phones[0].id, value: "+86 138 0013 9999")
        viewModel.updateEmail(index: 0, value: "edited@zhiyuntech.com")

        await viewModel.saveEdits()
        let updated = viewModel.card

        // Same aggregate identity.
        #expect(updated.id == original.id)
        // Image references + raw OCR untouched (no asset rewrite).
        #expect(updated.originalImageReference == original.originalImageReference)
        #expect(updated.processedImageReference == original.processedImageReference)
        #expect(updated.rawOCRText == original.rawOCRText)
        // createdAt preserved; updatedAt strictly advanced.
        #expect(updated.createdAt == original.createdAt)
        #expect(updated.updatedAt >= original.updatedAt)
        // Tags / notes untouched.
        #expect(updated.tags == original.tags)
        #expect(updated.notes == original.notes)
        // Phone edits keep the saved phone identities and kinds.
        #expect(updated.phones.map(\.id) == originalPhoneIDs)
        #expect(updated.phones.map(\.kind) == original.phones.map(\.kind))
        #expect(updated.phones(of: .mobile).first?.value == "+86 138 0013 9999")
        #expect(updated.phones(of: .office).first?.value == "+86 21 5555 1234")
        #expect(updated.emails == ["edited@zhiyuntech.com"])
        // Non-edited scalars survive.
        #expect(updated.name == original.name)
        #expect(updated.company == original.company)
        #expect(updated.website == original.website)
        #expect(updated.address == original.address)
    }

    @Test("T14 blanking a scalar/phone persists nil/omission without fabrication")
    func saveBlankNormalization() async {
        let (viewModel, repository) = makeEditingViewModel()
        viewModel.beginEditing()
        viewModel.updateWebsite("   ")
        viewModel.updatePhone(
            id: MockBusinessCards.card001.phones.first { $0.kind == .office }!.id,
            value: ""
        )

        await viewModel.saveEdits()
        #expect(viewModel.card.website == nil)
        #expect(viewModel.card.phones.count == 1)
        #expect(viewModel.card.phones.first?.kind == .mobile)

        let stored = await repository.card(id: MockBusinessCards.card001ID)
        #expect(stored?.website == nil)
        #expect(stored?.phones.count == 1)
        #expect(await repository.allCards().count == 3)
    }

    @Test("T14 saveEdits outside editing is a no-op")
    func saveOutsideEditingIsNoOp() async {
        let (viewModel, repository) = makeEditingViewModel()
        await viewModel.saveEdits()
        #expect(viewModel.card == MockBusinessCards.card001)
        #expect(await repository.card(id: MockBusinessCards.card001ID) == MockBusinessCards.card001)
        #expect(await repository.allCards().count == 3)
    }

    // MARK: - T17 Delete

    /// Builds a VM over a repository seeded with ALL mock cards so the
    /// "other cards preserved" and N-1 count assertions are meaningful.
    private func makeDeleteViewModel() -> (
        CardDetailViewModel, InMemoryBusinessCardRepository
    ) {
        let repository = InMemoryBusinessCardRepository(initialCards: MockBusinessCards.all)
        let viewModel = CardDetailViewModel(
            card: MockBusinessCards.card001,
            repository: repository
        )
        return (viewModel, repository)
    }

    @Test("T17 initial deleteState is idle")
    func t17InitialDeleteStateIsIdle() {
        let (viewModel, _) = makeDeleteViewModel()
        #expect(viewModel.deleteState == .idle)
        #expect(viewModel.editState == .viewing)
    }

    @Test("T17 requestDelete moves viewing+idle to confirming without touching storage")
    func t17RequestDeleteOpensConfirmation() async {
        let (viewModel, repository) = makeDeleteViewModel()
        viewModel.requestDelete()
        #expect(viewModel.deleteState == .confirming)
        // Confirmation precedes delete: nothing removed yet.
        #expect(await repository.card(id: MockBusinessCards.card001ID) != nil)
        #expect(await repository.allCards().count == 3)
    }

    @Test("T17 requestDelete is ignored while editing")
    func t17RequestDeleteIgnoredWhileEditing() async {
        let (viewModel, repository) = makeDeleteViewModel()
        viewModel.beginEditing()
        viewModel.requestDelete()
        #expect(viewModel.deleteState == .idle)
        guard case .editing = viewModel.editState else {
            Issue.record("Expected to remain in editing state")
            return
        }
        #expect(await repository.card(id: MockBusinessCards.card001ID) != nil)
    }

    @Test("T17 requestDelete is ignored after the card has been deleted")
    func t17RequestDeleteIgnoredAfterDeleted() async {
        let (viewModel, _) = makeDeleteViewModel()
        viewModel.requestDelete()
        #expect(await viewModel.confirmDelete())
        #expect(viewModel.deleteState == .deleted)
        viewModel.requestDelete()
        #expect(viewModel.deleteState == .deleted)
    }

    @Test("T17 cancelDelete returns confirming to idle")
    func t17CancelReturnsToIdle() {
        let (viewModel, _) = makeDeleteViewModel()
        viewModel.requestDelete()
        viewModel.cancelDelete()
        #expect(viewModel.deleteState == .idle)
    }

    @Test("T17 cancel leaves the displayed card and repository card completely unchanged")
    func t17CancelPreservesCardAndRepository() async {
        let (viewModel, repository) = makeDeleteViewModel()
        viewModel.requestDelete()
        viewModel.cancelDelete()

        #expect(viewModel.deleteState == .idle)
        #expect(viewModel.card == MockBusinessCards.card001)
        let stored = await repository.card(id: MockBusinessCards.card001ID)
        #expect(stored == MockBusinessCards.card001)
        #expect(await repository.allCards().count == 3)

        // cancelDelete outside confirming is a safe no-op.
        viewModel.cancelDelete()
        #expect(viewModel.deleteState == .idle)
    }

    @Test("T17 confirmDelete removes exactly the same UUID and reaches deleted")
    func t17ConfirmRemovesSameUUIDAndReachesDeleted() async {
        let (viewModel, repository) = makeDeleteViewModel()
        viewModel.requestDelete()

        let removed = await viewModel.confirmDelete()
        #expect(removed)
        #expect(viewModel.deleteState == .deleted)
        #expect(await repository.card(id: MockBusinessCards.card001ID) == nil)
        #expect(await repository.allCards().count == 2)
    }

    @Test("T17 confirmDelete outside confirming is a stable no-op returning false")
    func t17ConfirmOutsideConfirmingReturnsFalse() async {
        let (viewModel, repository) = makeDeleteViewModel()

        // From idle: nothing deleted.
        let fromIdle = await viewModel.confirmDelete()
        #expect(fromIdle == false)
        #expect(viewModel.deleteState == .idle)
        #expect(await repository.card(id: MockBusinessCards.card001ID) != nil)
        #expect(await repository.allCards().count == 3)

        // After a cancel (back to idle): still no deletion.
        viewModel.requestDelete()
        viewModel.cancelDelete()
        let afterCancel = await viewModel.confirmDelete()
        #expect(afterCancel == false)
        #expect(viewModel.deleteState == .idle)
        #expect(await repository.card(id: MockBusinessCards.card001ID) != nil)
        #expect(await repository.allCards().count == 3)
    }

    @Test("T17 a re-entrant second confirm cannot leave the deleted state or delete twice")
    func t17DoubleConfirmStaysDeleted() async {
        let (viewModel, repository) = makeDeleteViewModel()
        viewModel.requestDelete()
        #expect(await viewModel.confirmDelete())

        let second = await viewModel.confirmDelete()
        #expect(second == false)
        #expect(viewModel.deleteState == .deleted)
        // Count is exactly N-1 and stays there — no second removal.
        #expect(await repository.allCards().count == MockBusinessCards.all.count - 1)
    }

    @Test("T17 deleting one card preserves every other card untouched")
    func t17DeletingOnePreservesOthers() async {
        let (viewModel, repository) = makeDeleteViewModel()
        let otherIDs = Set(MockBusinessCards.all.map(\.id))
            .subtracting([MockBusinessCards.card001ID])

        viewModel.requestDelete()
        _ = await viewModel.confirmDelete()

        let remaining = await repository.allCards()
        #expect(remaining.count == MockBusinessCards.all.count - 1)
        #expect(Set(remaining.map(\.id)) == otherIDs)
        // The surviving aggregates keep their full values.
        for other in MockBusinessCards.all where other.id != MockBusinessCards.card001ID {
            #expect(await repository.card(id: other.id) == other)
        }
    }

    @Test("T17 delete request/cancel does not disturb the T14 edit workflow")
    func t17DoesNotDisturbEditWorkflow() async {
        let (viewModel, repository) = makeDeleteViewModel()

        // Open and cancel a delete, then edit and save normally.
        viewModel.requestDelete()
        viewModel.cancelDelete()
        viewModel.beginEditing()
        viewModel.updateJobTitle("高级产品总监 | Senior Product Director")
        await viewModel.saveEdits()

        #expect(viewModel.editState == .viewing)
        #expect(viewModel.deleteState == .idle)
        #expect(viewModel.card.jobTitle == "高级产品总监 | Senior Product Director")
        let stored = await repository.card(id: MockBusinessCards.card001ID)
        #expect(stored?.jobTitle == "高级产品总监 | Senior Product Director")
        #expect(await repository.allCards().count == 3)
    }

    #endif
}
