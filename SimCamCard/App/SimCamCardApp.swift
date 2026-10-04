//
//  SimCamCardApp.swift
//  SimCamCard
//
//  App composition root.
//
//  Responsibilities:
//   1. Construct the BusinessCardRepository (InMemory). Normal Week 2
//      launch seeds an empty repository. DEBUG UI tests may opt in to
//      deterministic mock fixtures via `-SimCamCardFixture <mode>`; this
//      never happens in Release or default DEBUG launches.
//   2. Construct the CardHolderViewModel with the repository injected.
//   3. Host the NavigationStack root and present CardHolderView.
//   4. Trigger initial card loading via `.task`.
//
//  The concrete repository type (InMemoryBusinessCardRepository) is NOT
//  passed into the View layer — only the ViewModel is passed.
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder
//   - spec/state-inventory.md S01 empty
//   - spec/reference-tests.md T01 Empty Card Holder
//

import SwiftUI

@main
struct SimCamCardApp: App {

    /// The shared card repository, owned by the composition root for the
    /// app's lifetime. Injected into BOTH the Card Holder (read) and the
    /// Scanner (T12 save) so a card saved after recognition appears in
    /// the same store the Holder lists. Assigned once in `init`.
    private let cardRepository: InMemoryBusinessCardRepository

    /// The shared group catalog repository (T16). App-lifetime ownership;
    /// injected into the Card Holder ViewModel alongside the card repo.
    private let groupRepository: InMemoryCardGroupRepository

    /// The shared image asset store (T12). Saves the original + processed
    /// image bytes under the references carried by each saved BusinessCard;
    /// Card Holder / Detail resolve those references back to real images.
    private let imageStore = InMemoryImageAssetStore()

    /// Holds the Card Holder ViewModel for the app's lifetime. `@State`
    /// (not `@StateObject`) is the standard holder for `@Observable`.
    @State private var viewModel: CardHolderViewModel

    /// Seeds the single shared repositories (empty for normal/Release
    /// launches; deterministic mock fixtures only for DEBUG UI-test opt-in
    /// via `-SimCamCardFixture <mode>`) and wires them into the Card Holder
    /// ViewModel. The default runtime NEVER injects mock data.
    init() {
        let cardRepo = InMemoryBusinessCardRepository(
            initialCards: SimCamCardFixture.initialCards()
        )
        let groupRepo = InMemoryCardGroupRepository()
        self.cardRepository = cardRepo
        self.groupRepository = groupRepo
        _viewModel = State(initialValue: CardHolderViewModel(
            repository: cardRepo,
            groupRepository: groupRepo
        ))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CardHolderView(
                    viewModel: viewModel,
                    cardRepository: cardRepository,
                    imageStore: imageStore
                )
            }
            .task {
                await viewModel.loadHolderData()
            }
        }
    }
}
