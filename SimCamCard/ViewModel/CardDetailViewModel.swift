//
//  CardDetailViewModel.swift
//  SimCamCard
//
//  UI-facing read-only state owner for the Card Detail page (P07).
//
//  Spec sources:
//   - spec/page-inventory.md P07 Card Detail
//   - spec/state-inventory.md S06 detailCollapsed (saved structured
//     fields visible)
//   - spec/reference-tests.md T13 Detail ("Saved structured fields are
//     visible in detail view.")
//
//  Architecture (one state, one owner):
//   - The Card Holder already owns the complete BusinessCard aggregate
//     loaded from the repository. Navigation carries the card's stable
//     UUID; the holder resolves it to the full value and passes it here.
//   - CardDetailViewModel therefore holds the BusinessCard value
//     directly — it does NOT perform a second repository lookup. The
//     frozen spec defines no requirement to re-fetch on detail open, and
//     Week 2 has no edit/persistence flow that would need fresh data.
//     A repository re-fetch will be introduced in a later increment only
//     if an actual requirement (e.g. T14 edit / T18 relaunch) needs it.
//
//  Scope discipline (Week 2 Increment 5):
//   - Read-only: no edit / delete / group / note / export actions.
//   - No separate DTO and no duplicated field structure — the frozen
//     Domain Model (BusinessCard) is the displayed state.
//   - Not responsible for persistence.
//
//  Swift 6 concurrency:
//   - @MainActor: UI state; @Observable: Swift Observation framework.
//

import Foundation
import Observation

@MainActor
@Observable
final class CardDetailViewModel {

    /// The saved card whose structured fields are displayed.
    ///
    /// `private(set)`: the skeleton never mutates the card (no editing
    /// this increment). The View reads domain fields directly — there is
    /// no parallel DTO or copied field layout.
    private(set) var card: BusinessCard

    init(card: BusinessCard) {
        self.card = card
    }
}
