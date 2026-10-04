//
//  CardDetailViewModel.swift
//  SimCamCard
//
//  UI-facing state owner for the Card Detail page (P07).
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail
//   - spec/state-inventory.md S06 detailCollapsed (saved structured
//     fields visible)
//   - spec/reference-tests.md T13 Detail ("Saved structured fields are
//     visible in detail view."), T14 Existing-Card Editing ("edited
//     title → stored BusinessCard changes → Detail displays corrected
//     title")
//
//  Architecture (one state, one owner):
//   - The Card Holder owns the loaded BusinessCard aggregates. Navigation
//     carries the card's stable UUID; the holder resolves it to the full
//     value and passes it here together with the shared Repository.
//   - CardDetailViewModel holds the displayed BusinessCard value
//     directly. T14 mutates that same aggregate IN PLACE conceptually:
//     saveEdits() projects the BusinessCardEditDraft, calls
//     repository.save(_:) (same UUID → replace, never a duplicate), then
//     updates `card` so the Detail reflects the correction immediately
//     without a round-trip to the Holder.
//
//  Edit state is a SEPARATE state family from the displayed card:
//  viewing / editing(draft) / saving(draft). The View never owns a
//  second copy of the editable fields — all mutations route through the
//  intents below into the draft held here.
//
//  Scope discipline:
//   - T14 edits existing saved-card values only. No phone/email row
//     add/delete UI, no kind change UI, no group/notes editing.
//   - ImageAssetStore is untouched by editing: image references do not
//     change, so existing assets stay valid.
//
//  Swift 6 concurrency:
//   - @MainActor: UI state; @Observable: Swift Observation framework.
//

import Foundation
import Observation

@MainActor
@Observable
final class CardDetailViewModel {

    /// Edit workflow state for the already-saved card (T14). Kept
    /// separate from the displayed `card` value, mirroring the
    /// RecognitionState/SaveState split on the scan side.
    ///
    /// - viewing: the read-only Detail is shown.
    /// - editing: `BusinessCardEditDraft` is the live editable buffer;
    ///   intents mutate only it.
    /// - saving: the same draft is being persisted; new edit intents and
    ///   re-entrant saves are ignored.
    enum EditState: Equatable {
        case viewing
        case editing(BusinessCardEditDraft)
        case saving(BusinessCardEditDraft)
    }

    /// The saved card whose structured fields are displayed. Updated
    /// IN PLACE (same aggregate id) after a successful T14 edit save.
    private(set) var card: BusinessCard

    /// The shared repository injected from the App composition root via
    /// the Holder. Required: T14 editing always persists; Previews /
    /// tests supply an InMemory repository seeded with the card.
    private let repository: any BusinessCardRepository

    private(set) var editState: EditState = .viewing

    init(card: BusinessCard, repository: any BusinessCardRepository) {
        self.card = card
        self.repository = repository
    }

    // MARK: - Editing lifecycle

    /// Detail → 编辑. Re-entering while already editing/saving keeps the
    /// current draft (stable no-op).
    func beginEditing() {
        switch editState {
        case .viewing:
            editState = .editing(BusinessCardEditDraft(source: card))
        case .editing, .saving:
            break
        }
    }

    /// 取消 / swipe-to-dismiss: discard the draft entirely. The
    /// displayed BusinessCard and the repository stay unchanged.
    func cancelEditing() {
        guard case .editing = editState else { return }
        editState = .viewing
    }

    /// 保存: project the draft, replace the same-id entity in the
    /// repository, then update the displayed card and return to viewing.
    /// The Detail therefore shows the corrected values immediately — no
    /// pop to the Holder is required (the Holder reloads its own copy
    /// via its existing onAppear load when the user navigates back).
    ///
    /// Re-entrant calls during .saving are ignored; a call outside
    /// .editing is ignored.
    func saveEdits() async {
        guard case .editing(let draft) = editState else { return }
        editState = .saving(draft)

        let updated = draft.updatedCard(timestamp: Date())
        await repository.save(updated)

        self.card = updated
        editState = .viewing
    }

    // MARK: - Draft intents
    //
    // Every mutation targets ONLY the in-flight draft; intents are
    // ignored outside .editing (including during .saving). The View
    // routes SwiftUI Bindings through these — it never holds the draft.

    func updateName(_ value: String) {
        mutateDraft { $0.name = value }
    }

    func updateCompany(_ value: String) {
        mutateDraft { $0.company = value }
    }

    func updateJobTitle(_ value: String) {
        mutateDraft { $0.jobTitle = value }
    }

    func updateWebsite(_ value: String) {
        mutateDraft { $0.website = value }
    }

    func updateAddress(_ value: String) {
        mutateDraft { $0.address = value }
    }

    /// Updates the phone row with the given stable saved PhoneNumber.id.
    /// Unknown ids (cannot occur via the form) are ignored.
    func updatePhone(id: UUID, value: String) {
        mutateDraft { draft in
            guard let index = draft.phones.firstIndex(where: { $0.id == id }) else { return }
            draft.phones[index].value = value
        }
    }

    /// Updates the email row at its stable positional index. Out-of-range
    /// indices (cannot occur via the form) are ignored.
    func updateEmail(index: Int, value: String) {
        mutateDraft { draft in
            guard draft.emails.indices.contains(index) else { return }
            draft.emails[index] = value
        }
    }

    /// Applies a draft mutation only while the state is `.editing`.
    private func mutateDraft(_ mutate: (inout BusinessCardEditDraft) -> Void) {
        guard case .editing(let current) = editState else { return }
        var updated = current
        mutate(&updated)
        editState = .editing(updated)
    }
}
