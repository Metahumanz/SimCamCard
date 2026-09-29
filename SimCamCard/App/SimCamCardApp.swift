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

    /// Holds the ViewModel for the app's lifetime. `@State` (not
    /// `@StateObject`) is the standard holder for `@Observable` classes.
    ///
    /// Repository seed: `SimCamCardFixture.initialCards()` returns `[]`
    /// for normal launches and Release builds. DEBUG UI tests opt in to
    /// deterministic mock fixtures via `-SimCamCardFixture <mode>` launch
    /// arguments. The default runtime NEVER injects mock data.
    @State private var viewModel = CardHolderViewModel(
        repository: InMemoryBusinessCardRepository(
            initialCards: SimCamCardFixture.initialCards()
        )
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CardHolderView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadCards()
            }
        }
    }
}
