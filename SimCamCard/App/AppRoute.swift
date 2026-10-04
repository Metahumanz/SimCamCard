//
//  AppRoute.swift
//  SimCamCard
//
//  Minimal typed navigation routes for the app's NavigationStack.
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder (main exits: Scanner, Detail)
//   - spec/page-inventory.md P02 Scanner (Back exit)
//   - spec/page-inventory.md P07 Card Detail
//   - spec/reference-tests.md T02 Enter Scanner / T13 Detail
//
//  Week 2 Increment 5 introduced the first real route: selecting a card
//  in the Card Holder pushes the read-only Card Detail page.
//  Week 2 Increment 6 adds the second real route: the Card Holder "+"
//  scan entry pushes the static Scanner UI shell.
//
//  Scope discipline:
//   - Only routes actually used by the current increments are declared.
//   - `.capture`, `.photoImport`, `.crop`, `.recognition`, `.permission`,
//     `.edit`, `.group`, `.notes`, `.export` etc. are NOT added ahead of
//     their increments (no speculative dead scaffolding — same rule that
//     removed the zero-case enum in Increment 3).
//

import Foundation

enum AppRoute: Hashable {

    /// Pushes the read-only Card Detail page for the card with the given
    /// stable id.
    ///
    /// Navigation selection carries the UUID (a stable identity), never a
    /// row index — the BusinessCardRepository contract defines no ordering
    /// for `allCards()`. The holder resolves the UUID to the full
    /// `BusinessCard` value it already owns before constructing the
    /// CardDetailViewModel.
    case cardDetail(UUID)

    /// Pushes the static Scanner UI shell (P02) from the Card Holder scan
    /// entry. This is a read-only navigation target in Week 2: no live
    /// camera, permission, capture, import or recognition behavior.
    case scan

    /// Pushes the P08 Search Results page from the Card Holder search
    /// entry (T15). The page binds the shared CardHolderViewModel's
    /// search query; result rows reuse the `.cardDetail` route — there is
    /// no second Detail navigation path.
    case search

    /// Pushes the P09 Group Management page from the Card Holder group
    /// entry (T16). The page shares the same CardHolderViewModel for
    /// group catalog, selection, and filtering state.
    case groups
}
