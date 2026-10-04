//
//  CardSearchView.swift
//  SimCamCard
//
//  Week 4 Increment 6 — P08 Search Results (T15 Search).
//
//  Spec sources:
//   - spec/page-inventory.md P08 Search Results ("Search cards by
//     supported fields", exits: Detail / Back)
//   - spec/state-inventory.md S01 `searching`
//   - spec/reference-tests.md T15 (name, company, jobTitle, phone, email)
//   - Evidence: evidence/screenshots/REF-search-01-by-name.png,
//     evidence/screenshots/REF-search-02-by-company.png
//
//  Reference observations (frozen evidence):
//   - Search is a DEDICATED pushed page, not an in-list search field:
//     custom top bar with a back chevron, a rounded search field
//     (magnifier + editable text + in-field × clear), and a result
//     section headed "名片夹名片 <n>".
//   - The Holder entry bar placeholder is "请输入姓名/公司/职位搜索".
//   - Result rows are the same card rows as the Holder and tapping one
//     opens the same Card Detail.
//
//  Minimal-fidelity decisions (PARTIAL vs full Reference surface):
//   - The 综合/名片/企业 segmented control, 浏览模式 link, card-image
//     thumbnails and async "正在加载" are not reproduced: our frozen
//     domain has no enterprise index and search over the in-memory
//     snapshot is synchronous.
//
//  State ownership:
//   - The SHARED CardHolderViewModel owns `searchQuery` and the
//     `visibleCards` projection. This View holds no [BusinessCard] and
//     no second query string; the TextField binds the ViewModel.
//   - Result rows are NavigationLinks on the existing
//     AppRoute.cardDetail(UUID) route resolved by the Holder's
//     navigationDestination — there is no second Detail path.
//   - Back (custom chevron matching the Reference) clears the query and
//     pops; returning to a Detail pushed from a result does NOT clear
//     (no onDisappear reset), so the result list survives Detail round
//     trips. The in-field × restores the full snapshot in place.
//

import SwiftUI

struct CardSearchView: View {

    /// Shared Holder state owner (query + visibleCards projection).
    @Bindable var viewModel: CardHolderViewModel

    /// Forwarded to BusinessCardRow for real session-saved thumbnails
    /// (nil → text-only rows; same rule as the Holder).
    let imageStore: (any ImageAssetStore)?

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            topBar
            results
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // Focus the field immediately so typing starts at once,
            // mirroring the Reference entry behavior.
            isFieldFocused = true
        }
    }

    // MARK: - Custom top bar (back chevron + rounded search field)

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.clearSearch()
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel("返回")
            .accessibilityIdentifier("card-search-back")

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("请输入姓名/公司/职位搜索", text: $viewModel.searchQuery)
                    .focused($isFieldFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("card-holder-search")

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("清除搜索")
                    .accessibilityIdentifier("card-holder-search-clear")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.07))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {
        if viewModel.isSearching && viewModel.visibleCards.isEmpty {
            // Active query with zero hits — distinct from the Holder's
            // own "no cards at all" empty state.
            ContentUnavailableView.search(text: viewModel.searchQuery)
                .accessibilityIdentifier("card-holder-search-empty")
        } else {
            List {
                Section {
                    ForEach(viewModel.visibleCards) { card in
                        NavigationLink(value: AppRoute.cardDetail(card.id)) {
                            BusinessCardRow(card: card, imageStore: imageStore)
                        }
                        .accessibilityIdentifier("card-row-\(card.id.uuidString)")
                    }
                } header: {
                    Text("名片夹名片 \(viewModel.visibleCards.count)")
                }
            }
        }
    }
}

#if DEBUG

#Preview("Card Search") {
    let viewModel = CardHolderViewModel(
        repository: InMemoryBusinessCardRepository(
            initialCards: MockBusinessCards.all
        ),
        groupRepository: InMemoryCardGroupRepository()
    )
    return NavigationStack {
        CardSearchView(viewModel: viewModel, imageStore: nil)
    }
    .task { await viewModel.loadHolderData() }
}

#endif
