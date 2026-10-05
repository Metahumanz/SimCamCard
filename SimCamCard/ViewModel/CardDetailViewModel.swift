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

    /// Delete workflow state for the saved card (T17), S06 `deleted`.
    /// Kept independent from `EditState` — viewing and delete confirmation
    /// are orthogonal to the edit draft family.
    ///
    /// - idle: no delete interaction; the read-only Detail is shown.
    /// - confirming: the native 「删除名片」 confirmation is presented;
    ///   the repository/card are still untouched.
    /// - deleting: the repository delete(id:) call is in flight; re-entrant
    ///   confirms are ignored.
    /// - deleted: the aggregate has been removed; the View dismisses.
    enum DeleteState: Equatable {
        case idle
        case confirming
        case deleting
        case deleted
    }

    /// Notes workflow state for the P10 Notes page (S08). A third
    /// independent state family: the displayed BusinessCard remains the
    /// single source of truth for the note history (`card.notes`), and
    /// only `saveNote` mutates that aggregate — through the same
    /// `repository.save(_:)` same-id replace path as T14 edits. The View
    /// never owns a second `[CardNote]` copy.
    ///
    /// - historyVisible: the Notes history is shown.
    /// - addingNote: the multiline editor holds a live draft String;
    ///   intents mutate only it; cancel discards it without touching the
    ///   card or repository.
    /// - saving: the trimmed note is being persisted; editor intents and
    ///   re-entrant saves are ignored.
    enum NoteState: Equatable {
        case historyVisible
        case addingNote(String)
        case saving(String)
    }

    /// The saved card whose structured fields are displayed. Updated
    /// IN PLACE (same aggregate id) after a successful T14 edit save.
    private(set) var card: BusinessCard

    /// The shared repository injected from the App composition root via
    /// the Holder. Required: T14 editing always persists; Previews /
    /// tests supply an InMemory repository seeded with the card.
    private let repository: any BusinessCardRepository

    private(set) var editState: EditState = .viewing

    /// T17 delete workflow state (see DeleteState).
    private(set) var deleteState: DeleteState = .idle

    /// P10 notes workflow state (see NoteState).
    private(set) var noteState: NoteState = .historyVisible

    /// Note history projected from the single owning BusinessCard
    /// aggregate. The View reads this directly; there is no second copy.
    var notes: [CardNote] { card.notes }

    init(card: BusinessCard, repository: any BusinessCardRepository) {
        self.card = card
        self.repository = repository
    }

    // MARK: - Editing lifecycle

    /// Detail → 编辑. Re-entering while already editing/saving keeps the
    /// current draft (stable no-op). While the P10 Notes workflow is
    /// active (`.addingNote`/`.saving`) editing cannot start — the
    /// displayed aggregate must not have two mutating families live.
    func beginEditing() {
        switch editState {
        case .viewing:
            guard noteState == .historyVisible else { return }
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

    // MARK: - Delete lifecycle (T17, S06 deleted)
    //
    // Delete is a separate state family from editing. The confirmation
    // precedes every deletion (reference-tests T17); cancel leaves the
    // card and repository completely untouched. The repository never
    // throws today, so there is no fabricated failed state.

    /// More → 删除: open the native confirmation. Allowed only while the
    /// Detail is read-only (`.viewing`), no delete flow is active
    /// (`.idle`), and no P10 Notes workflow is active; no-op during
    /// editing/saving, note adding/saving, and once deleting/deleted.
    func requestDelete() {
        guard editState == .viewing, deleteState == .idle, noteState == .historyVisible
        else { return }
        deleteState = .confirming
    }

    /// 取消 on the confirmation: return to idle. The displayed card and
    /// the repository are not touched. No-op outside `.confirming`.
    func cancelDelete() {
        guard deleteState == .confirming else { return }
        deleteState = .idle
    }

    /// 删除名片 on the confirmation: persist the hard delete through the
    /// existing repository contract, then mark `.deleted`. Returns true
    /// only when a deletion was actually performed; a re-entrant /
    /// out-of-state call is a stable no-op returning false.
    @discardableResult
    func confirmDelete() async -> Bool {
        guard deleteState == .confirming else { return false }
        deleteState = .deleting
        await repository.delete(id: card.id)
        deleteState = .deleted
        return true
    }

    // MARK: - Notes lifecycle (P10, S08)
    //
    // The Notes page is a push page that reads the history directly from
    // `card.notes`. Adding a note appends to that SAME BusinessCard
    // aggregate (every other field byte-identical) and persists it with
    // the existing repository.save path — there is no draft aggregate and
    // no second owning store. Cancel discards only the in-flight String.

    /// 新增备注: enter the editor with an empty draft. Allowed only while
    /// the history is visible and no edit/delete workflow is active;
    /// re-entrant calls and calls during `.saving` are stable no-ops.
    func beginAddingNote() {
        guard noteState == .historyVisible,
              editState == .viewing,
              deleteState == .idle
        else { return }
        noteState = .addingNote("")
    }

    /// Updates the live note draft only while `.addingNote`. The View
    /// routes the TextEditor Binding through this — it never holds the
    /// draft String. No-op in `.historyVisible`/`.saving`.
    func updateNoteDraft(_ value: String) {
        guard case .addingNote = noteState else { return }
        noteState = .addingNote(value)
    }

    /// 取消: discard the draft and return to the history. The displayed
    /// BusinessCard and the repository stay unchanged. No-op outside
    /// `.addingNote` (in particular during `.saving`).
    func cancelAddingNote() {
        guard case .addingNote = noteState else { return }
        noteState = .historyVisible
    }

    /// 保存: trim the draft, append a CardNote to the same-id aggregate,
    /// persist it via `repository.save(_:)`, update the displayed card,
    /// and return to the history (which immediately contains the new
    /// note). Whitespace-only drafts remain in `.addingNote`; the View
    /// also disables the button, so this is a defensive guard.
    ///
    /// Re-entrant calls and calls outside `.addingNote` (including a
    /// double-tap that lands in `.saving`) are ignored — the note is
    /// appended exactly once.
    @discardableResult
    func saveNote(id: UUID = UUID(), createdAt: Date = Date()) async -> Bool {
        guard case .addingNote(let draft) = noteState else { return false }

        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return false }

        noteState = .saving(trimmed)

        let note = CardNote(id: id, text: trimmed, createdAt: createdAt)
        let updated = Self.appending(note: note, to: card, updatedAt: createdAt)
        await repository.save(updated)

        self.card = updated
        noteState = .historyVisible
        return true
    }

    /// Builds the updated aggregate with `note` appended. Every other
    /// field is carried over unchanged: identity, both image references,
    /// raw OCR text, structured fields, the same PhoneNumber ids, emails,
    /// tags, existing notes (same ids/order), and the original
    /// `createdAt`. Only `updatedAt` advances to the save instant.
    private nonisolated static func appending(
        note: CardNote,
        to card: BusinessCard,
        updatedAt: Date
    ) -> BusinessCard {
        BusinessCard(
            id: card.id,
            originalImageReference: card.originalImageReference,
            processedImageReference: card.processedImageReference,
            rawOCRText: card.rawOCRText,
            name: card.name,
            company: card.company,
            jobTitle: card.jobTitle,
            website: card.website,
            address: card.address,
            phones: card.phones,
            emails: card.emails,
            tags: card.tags,
            notes: card.notes + [note],
            createdAt: card.createdAt,
            updatedAt: updatedAt
        )
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
