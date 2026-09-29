//
//  AppRoute.swift
//  SimCamCard
//
//  Minimal typed navigation routes for the app's NavigationStack.
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder (main exit: Detail)
//   - spec/page-inventory.md P07 Card Detail
//   - spec/reference-tests.md T13 Detail
//
//  Week 2 Increment 5 introduces the FIRST real route: selecting a card
//  in the Card Holder pushes the read-only Card Detail page.
//
//  Scope discipline:
//   - Only routes actually used by the current increment are declared.
//   - `.scan`, `.edit`, `.group`, `.notes`, `.export` etc. are NOT added
//     ahead of their increments (no speculative dead scaffolding — same
//     rule that removed the zero-case enum in Increment 3).
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
}
