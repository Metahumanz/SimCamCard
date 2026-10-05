//
//  CardNotesView.swift
//  SimCamCard
//
//  P10 Notes push page (spec/page-inventory.md P10: view/add notes/
//  history; state-inventory.md S08 historyVisible / addingNote).
//
//  Reference evidence: evidence/screenshots/REF-notes-01-page.png
//   - A pushed page titled 备注 with a plain back chevron.
//   - A full-width bright-blue bottom pill 「+ 新增备注」.
//   - History rows show text plus a timestamp on the same visual row
//     (the Reference's only captured row is a SYSTEM save record with
//     title「名片保存」/「来源：拍名片保存」; that typed-entry shape has
//     no equivalent in the frozen CardNote { id, text, createdAt }
//     domain, so custom notes render text + timestamp only).
//   - Timestamp format observed: yyyy-MM-dd HH:mm.
//   - The Reference captured neither the add-note editor nor an empty
//     history; both are SimCamCard completion behavior (see the S08
//     fidelity boundary in ai/changes.md).
//
//  Ownership: this view holds NO copy of the history and NO repository.
//  It reads CardDetailViewModel.notes (projected from the single owning
//  BusinessCard aggregate) and routes every draft mutation through the
//  view model intents. A successful save appends to that same aggregate
//  and the new row is visible immediately — no pop/reload required.
//

import SwiftUI

struct CardNotesView: View {

    let viewModel: CardDetailViewModel

    var body: some View {
        // The page marker `card-notes` lives on a CHILLESS background
        // layer, never on the container that parents the controls:
        // SwiftUI propagates a container-level accessibilityIdentifier
        // down to child Buttons/TextEditors and overrides their own
        // identifiers (same pitfall documented in ScanEntryView).
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .accessibilityElement()
                .accessibilityIdentifier("card-notes")

            pageContent
                .navigationTitle("备注")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch viewModel.noteState {
        case .historyVisible:
            noteHistory
        case .addingNote, .saving:
            noteEditor
        }
    }

    // MARK: - History (historyVisible)

    private var noteHistory: some View {
        List {
            if viewModel.notes.isEmpty {
                // Empty state: NOT captured in the Reference
                // (completion behavior).
                Text("暂无备注")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .accessibilityIdentifier("card-notes-empty")
            } else {
                ForEach(viewModel.notes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.text)
                            .font(.body)
                        Text(Self.timestampFormatter.string(from: note.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityIdentifier(
                        "card-note-\(note.id.uuidString)"
                    )
                }
            }
        }
        // History-state marker on a CHILDLESS overlay node: an identifier
        // directly on the List/VStack container would propagate into the
        // row hierarchy and override the per-row card-note-<uuid> ids
        // (container-identifier pitfall, see ScanEntryView).
        .overlay(alignment: .topTrailing) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityIdentifier("card-notes-history")
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.beginAddingNote()
            } label: {
                Text("+ 新增备注")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("card-notes-add")
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(.bar)
        }
    }

    // MARK: - Editor (addingNote / saving)
    //
    // The Reference did not capture the add-note editor (S08), so the
    // layout is completion behavior: an inline multiline editor on the
    // same Notes page (not a separate REF-captured screen), with a
    // bottom 取消 / 保存 bar. Save is enabled only for non-whitespace
    // drafts; while .saving all controls are disabled and an activity
    // indicator is shown.

    private var noteEditor: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)

                if draftText.isEmpty {
                    Text("输入备注内容")
                        .font(.body)
                        .foregroundStyle(.secondary.opacity(0.7))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: draftBinding)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .disabled(isSaving)
                    .accessibilityIdentifier("card-note-editor")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer(minLength: 0)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button(role: .cancel) {
                    viewModel.cancelAddingNote()
                } label: {
                    Text("取消")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isSaving)
                .accessibilityIdentifier("card-note-cancel")

                Button {
                    Task { await viewModel.saveNote() }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                        }
                        Text("保存")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canSave)
                .accessibilityIdentifier("card-note-save")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(.bar)
        }
    }

    // MARK: - Draft bindings / derived state

    /// The TextEditor reads the live draft payload in both adding and
    /// saving states (so the text remains visible during the short save),
    /// and routes every keystroke through the view model intent — the
    /// View never owns the draft String.
    private var draftBinding: Binding<String> {
        Binding(
            get: {
                switch viewModel.noteState {
                case .addingNote(let draft), .saving(let draft):
                    draft
                case .historyVisible:
                    ""
                }
            },
            set: { viewModel.updateNoteDraft($0) }
        )
    }

    private var draftText: String {
        switch viewModel.noteState {
        case .addingNote(let draft), .saving(let draft):
            draft
        case .historyVisible:
            ""
        }
    }

    private var isSaving: Bool {
        if case .saving = viewModel.noteState { true } else { false }
    }

    private var canSave: Bool {
        guard case .addingNote(let draft) = viewModel.noteState else {
            return false
        }
        return draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    /// Timestamp formatter for history rows. The `yyyy-MM-dd HH:mm`
    /// format is the single visible timestamp fact in REF-notes-01.
    /// @MainActor-isolated because DateFormatter is not Sendable; it is
    /// only ever read while rendering on the main actor.
    @MainActor
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}

#if DEBUG

// MARK: - SwiftUI Previews

#Preview("Card Notes — empty") {
    NavigationStack {
        CardNotesView(
            viewModel: CardDetailViewModel(
                card: MockBusinessCards.card001,
                repository: InMemoryBusinessCardRepository(
                    initialCards: MockBusinessCards.all
                )
            )
        )
    }
}

#Preview("Card Notes — with history") {
    let card = MockBusinessCards.card001
    let noted = BusinessCard(
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
        notes: [
            CardNote(
                id: UUID(uuidString: "A0000001-0000-0000-0000-000000000001")!,
                text: "展会现场交换名片，对云端识别方案很感兴趣，约下周电话沟通。",
                createdAt: Date(timeIntervalSince1970: 1_790_000_000)
            )
        ],
        createdAt: card.createdAt,
        updatedAt: card.updatedAt
    )
    return NavigationStack {
        CardNotesView(
            viewModel: CardDetailViewModel(
                card: noted,
                repository: InMemoryBusinessCardRepository(initialCards: [noted])
            )
        )
    }
}

#endif
