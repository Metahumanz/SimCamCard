//
//  SimCamCardApp.swift
//  SimCamCard
//
//  App composition root.
//
//  Responsibilities:
//   1. Construct the BusinessCardRepository (InMemory, empty — normal
//      Week 2 launch; no mock data injection).
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
    @State private var viewModel = CardHolderViewModel(
        repository: InMemoryBusinessCardRepository()
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
