//
//  CardHolderView.swift
//  SimCamCard
//
//  Root content view for the Card Holder page (P01).
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder (empty / populated;
//     main exit: Detail)
//   - spec/state-inventory.md S01 empty / populated
//   - spec/reference-tests.md T01 Empty Card Holder / T13 Detail
//     (selecting a card opens Card Detail)
//   - Evidence: evidence/screenshots/REF-card-holder-01-empty.png,
//     evidence/screenshots/REF-card-holder-02-after-save.png
//
//  UI evidence → View element mapping (see ai/changes.md for full table):
//   - "名片夹" page identity      → navigationTitle("名片夹")
//   - "+" scan entry (header)     → toolbar trailing NavigationLink to
//                                   AppRoute.scan (T02 navigation, Week 2
//                                   Increment 6; NOT a verified replica of
//                                   the Reference header "+" button)
//   - "名片 (0张)" count indicator → ContentUnavailableView title (Week 2
//                                   scaffold — NOT a verified replica of the
//                                   Reference empty-state visual)
//   - Search bar (T15)             → tappable rounded bar with magnifier
//                                   and Reference placeholder
//                                   "请输入姓名/公司/职位搜索"; pushes the
//                                   dedicated P08 CardSearchView. The
//                                   Holder list itself stays on the full
//                                   repository snapshot.
//   - Quick Action Grid            → Group Management = in scope, deferred;
//                                   Contact Map / Analytics = excluded
//   - Tutorial card                → excluded (promotional content)
//   - Bottom tab bar               → excluded (switches to excluded pages)
//   - Card row (populated)         → BusinessCardRow inside a NavigationLink
//                                   to AppRoute.cardDetail(card.id)
//
//  Navigation (Week 2 Increment 5):
//   - Rows are NavigationLinks carrying the card's stable UUID
//     (AppRoute.cardDetail(UUID)) — never a row index; Repository
//     ordering remains unspecified.
//   - `navigationDestination` resolves the UUID against the cards this
//     holder already owns and constructs CardDetailViewModel with the
//     full BusinessCard value (no second repository fetch).
//
//  State ownership (one state, one owner):
//   - Repository = data source abstraction
//   - CardHolderViewModel = SOLE owner of `cards`
//   - CardHolderView = rendering + user intent; reads `viewModel.cards`
//     directly, does NOT hold its own [BusinessCard]
//
//  Card row accessibility:
//   - Each row carries `card-row-<UUID>` so T01 empty UI test can verify
//     NO card rows exist (NSPredicate identifier BEGINSWITH "card-row-"),
//     and populated / detail UI tests can locate and tap specific rows
//     by stable id. UI tests verify membership only, never row position.
//
//  Week 2 Increment 6: the toolbar "+" is now a typed NavigationLink to
//  AppRoute.scan (T02 scan-entry navigation + Scanner UI shell).
//
//  Week 4 Increment 6 (T15): a tappable Reference-style search bar above
//  the list pushes AppRoute.search → CardSearchView (P08). Search is a
//  presentation-only filter owned by CardHolderViewModel; the Holder
//  list continues to render the full `cards` snapshot.
//

import SwiftUI

struct CardHolderView: View {

    /// The sole state owner for Card Holder card data.
    /// The View reads `viewModel.cards` directly; it does NOT hold its
    /// own `[BusinessCard]`.
    let viewModel: CardHolderViewModel

    /// Persistence dependencies forwarded to the Scanner (T12 Save). The
    /// composition root injects the shared instances so a card saved after
    /// recognition lands in the same repository this Holder reads. Both
    /// are optional: the Holder lists cards without them, and Previews /
    /// tests that never enter the Scanner may omit them.
    let cardRepository: (any BusinessCardRepository)?
    let imageStore: (any ImageAssetStore)?

    /// T19 shared contact-export service forwarded into every
    /// CardDetailViewModel opened from this Holder. Required from the
    /// composition root (one shared SystemContactExporter for the app);
    /// DEBUG Previews pass a scripted DebugContactExporter so they never
    /// touch the real CNContactStore.
    let contactExporter: any ContactExporting

    init(
        viewModel: CardHolderViewModel,
        cardRepository: (any BusinessCardRepository)? = nil,
        imageStore: (any ImageAssetStore)? = nil,
        contactExporter: any ContactExporting
    ) {
        self.viewModel = viewModel
        self.cardRepository = cardRepository
        self.imageStore = imageStore
        self.contactExporter = contactExporter
    }

    var body: some View {
        Group {
            if viewModel.isGroupFiltered {
                // S01 groupFiltered — show only cards in the selected group.
                List(viewModel.groupFilteredCards) { card in
                    NavigationLink(value: AppRoute.cardDetail(card.id)) {
                        BusinessCardRow(card: card, imageStore: imageStore)
                    }
                    .accessibilityIdentifier("card-row-\(card.id.uuidString)")
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    groupFilterBanner
                }
            } else if viewModel.cards.isEmpty {
                ContentUnavailableView {
                    Label("名片 (0张)", systemImage: "rectangle.stack")
                }
                .accessibilityIdentifier("card-holder-empty")
            } else {
                List(viewModel.cards) { card in
                    NavigationLink(value: AppRoute.cardDetail(card.id)) {
                        // T12: forward the store so cards saved this
                        // session render their real processed-image
                        // thumbnail (fixture-seeded / preview cards
                        // without stored assets stay text-only).
                        BusinessCardRow(card: card, imageStore: imageStore)
                    }
                    .accessibilityIdentifier("card-row-\(card.id.uuidString)")
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            // T15 Reference entry (REF-card-holder-02-after-save.png):
            // a rounded search bar with magnifier + placeholder. Tapping
            // pushes the dedicated P08 Search Results page; the Holder
            // list below always renders the full snapshot.
            NavigationLink(value: AppRoute.search) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("请输入姓名/公司/职位搜索")
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(0.07))
                )
                .contentShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("card-holder-search-entry")
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
        .navigationTitle("名片夹")
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .cardDetail(let id):
                // Resolve the stable id to the complete aggregate this
                // holder already owns. UUID selection (not index) keeps
                // navigation independent of unspecified repository order.
                // T14: forward the shared Repository so Existing-Card
                // Editing replaces the same-id entity in the store the
                // Holder lists. Production always injects it; Previews /
                // throwaway contexts fall back to an isolated repository
                // seeded with this card.
                //
                // T17: onDeleted explicitly reloads this Holder's cards +
                // groups snapshot AFTER the shared repository has removed
                // the card and BEFORE the Detail is popped, so the list,
                // group card counts, active filter and future search all
                // reflect the deletion without relying on onAppear timing.
                if let card = viewModel.cards.first(where: { $0.id == id }) {
                    CardDetailView(
                        viewModel: CardDetailViewModel(
                            card: card,
                            repository: cardRepository
                                ?? InMemoryBusinessCardRepository(initialCards: [card]),
                            contactExporter: contactExporter
                        ),
                        onDeleted: {
                            await viewModel.loadHolderData()
                        }
                    )
                }
                // A missing id cannot occur via holder row taps; an empty
                // fallback is sufficient for the typed initializer.
            case .scan:
                // P02 Scanner. Forward the shared persistence dependencies
                // so the T12 save path (recognition → corrected draft →
                // final BusinessCard) writes into the same repository this
                // Holder lists, and stores the card's image assets.
                ScanEntryView(cardRepository: cardRepository, imageStore: imageStore)
            case .search:
                // P08 Search Results (T15). Shares this Holder's
                // ViewModel (query + visibleCards projection) and reuses
                // the AppRoute.cardDetail rows/destination above.
                CardSearchView(viewModel: viewModel, imageStore: imageStore)
            case .groups:
                // P09 Group Management (T16). Shares this Holder's
                // ViewModel (group catalog, selection, filter state).
                GroupManagementView(viewModel: viewModel, imageStore: imageStore)
            }
        }
        .onAppear {
            // Reload on every appearance so a card saved in the Scanner
            // (T12) is listed immediately when P06 完成 pops back here.
            // The repository defines no ordering; membership is what
            // matters. Initial load also runs via the App's `.task`.
            Task { await viewModel.loadHolderData() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // T16 Group entry — replaces the Quick Action Grid
                // placeholder with a real navigation target.
                NavigationLink(value: AppRoute.groups) {
                    Image(systemName: "folder")
                }
                .accessibilityLabel("分组")
                .accessibilityIdentifier("card-holder-groups")
            }
            ToolbarItem(placement: .topBarTrailing) {
                // Typed navigation entry to the Scanner shell (T02).
                // Reuses the same NavigationStack + AppRoute system as
                // card rows; no parallel Bool/sheet state.
                NavigationLink(value: AppRoute.scan) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("扫描")
                .accessibilityIdentifier("scan-entry")
            }
        }
    }
    // MARK: - Group filter banner

    /// Shown above the list when a group filter is active (S01
    /// `groupFiltered`). Displays the selected group name and offers a
    /// × to clear the filter.
    @ViewBuilder
    private var groupFilterBanner: some View {
        if let group = viewModel.selectedGroup {
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)
                Text(group.name)
                    .font(.subheadline.weight(.medium))
                Text("(\(viewModel.groupFilteredCards.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Button {
                    viewModel.clearGroupFilter()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("清除分组筛选")
                .accessibilityIdentifier("group-filter-clear")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)
            .accessibilityIdentifier("group-filter-active")
        }
    }
}

#if DEBUG

// MARK: - SwiftUI Previews
//
// Both Previews wrap CardHolderView in NavigationStack because
// `navigationTitle` / `toolbar` / `navigationDestination` rely on the
// enclosing navigation container environment.
//
// Populated Preview uses the real Repository → CardHolderViewModel → View
// data path. The View never hardcodes a [BusinessCard] source of truth;
// it reads `viewModel.cards` like the production code does. The async
// `loadCards()` is triggered via a minimal `.task`; no fake ViewModel
// initializer is added to the production type.

#Preview("Empty Card Holder") {
    NavigationStack {
        CardHolderView(
            viewModel: CardHolderViewModel(
                repository: InMemoryBusinessCardRepository(),
                groupRepository: InMemoryCardGroupRepository()
            ),
            contactExporter: DebugContactExporter(mode: .allowed)
        )
    }
}

#Preview("Populated Card Holder") {
    let viewModel = CardHolderViewModel(
        repository: InMemoryBusinessCardRepository(
            initialCards: MockBusinessCards.all
        ),
        groupRepository: InMemoryCardGroupRepository()
    )
    return NavigationStack {
        CardHolderView(
            viewModel: viewModel,
            contactExporter: DebugContactExporter(mode: .allowed)
        )
        .task { await viewModel.loadHolderData() }
    }
}

#endif
