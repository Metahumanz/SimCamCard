//
//  BusinessCardSearchMatcher.swift
//  SimCamCard
//
//  Week 4 Increment 6 — T15 Search deterministic predicate.
//
//  Spec sources:
//   - spec/reference-tests.md T15 Search (final implementation must
//     support name, company, job title, phone, email; current black-box
//     evidence directly verifies only name and company)
//   - spec/page-inventory.md P08 Search Results
//   - spec/state-inventory.md S01 `searching` (query active)
//
//  Pure, deterministic, side-effect-free:
//   - no repository access, no BusinessCard mutation, no logging;
//   - the matcher does not own a query — callers (CardHolderViewModel)
//     keep the query string and project the visible snapshot;
//   - empty (or whitespace-only) query matches every card, so clearing
//     the field restores the full holder without a second code path.
//
//  Matching rules:
//   - name / company / jobTitle / each email: trimmed query,
//     case-insensitive substring (`张伟`, `智云`, `Product Director`,
//     `wei.zhang`). nil fields never fabricate a match.
//   - phones: both stored value and query are reduced to ASCII digits,
//     then substring-matched. `+86 138 0013 8000` normalizes to
//     `8613800138000`, so the digits-only query `13800138000` and the
//     formatted query `+86 138 0013 8000` both hit. Every stored phone
//     is tested, so a second number matches independently.
//

import Foundation

nonisolated struct BusinessCardSearchMatcher: Sendable {

    /// Returns true when `card` matches the (untrimmed) `query`.
    func matches(card: BusinessCard, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        if Self.textContains(haystack: card.name, needle: trimmed) { return true }
        if Self.textContains(haystack: card.company, needle: trimmed) { return true }
        if Self.textContains(haystack: card.jobTitle, needle: trimmed) { return true }

        if card.emails.contains(where: { Self.textContains(haystack: $0, needle: trimmed) }) {
            return true
        }

        let normalizedQuery = Self.digits(trimmed)
        if !normalizedQuery.isEmpty,
           card.phones.contains(where: { Self.digits($0.value).contains(normalizedQuery) }) {
            return true
        }

        return false
    }

    /// Case-insensitive substring test for optional text. A nil field
    /// never matches; no empty-string value is fabricated.
    private static func textContains(haystack: String?, needle: String) -> Bool {
        guard let haystack else { return false }
        return haystack.range(of: needle, options: .caseInsensitive) != nil
    }

    /// Reduces a formatted phone string (or phone query) to its ASCII
    /// digits: `+86 138 0013 8000` → `8613800138000`.
    private static func digits(_ text: String) -> String {
        text.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
            .map(String.init)
            .joined()
    }
}
