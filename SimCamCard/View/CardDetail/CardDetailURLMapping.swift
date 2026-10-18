//
//  CardDetailURLMapping.swift
//  SimCamCard
//
//  Pure URL construction for the Card Detail page tap actions
//  (Final Delivery Phase 1.1 — B-01).
//
//  Assignment §10 requires the detail page to support tapping
//  phone / email / website. The assignment explicitly allows
//  "native system components" for external-app invocation.
//
//  Design:
//   - Pure functions, no state, no UIKit/SwiftUI dependency.
//   - Invalid OR missing values return nil → the View never calls
//     openURL for an invalid value (frozen requirement: invalid or
//     missing phone/email/website values must not trigger a system
//     action).
//   - phoneURL rejects empty values AND non-empty values without a
//     single dialable digit (e.g. "not-a-phone", "()-"). Visual
//     separators (spaces, dashes, parentheses) in a digit-bearing
//     value are preserved per RFC 3966.
//   - emailURL rejects empty values AND non-empty values that fail a
//     basic structural check (one '@', non-empty local part and a
//     dotted domain with a non-empty TLD, no whitespace).
//   - Website URLs are safety-checked: only http/https schemes
//     pass; a bare domain is upgraded to https://; an explicit
//     non-web scheme (ftp://, file://, javascript:…) is rejected.
//
//  Testability: the pure functions are Unit-tested directly.
//  The actual openURL handoff is a system-level concern that
//  cannot be verified in the Simulator (no Phone/Mail/Safari
//  app to receive the URL). UI tests verify that rows are
//  tappable Buttons; the URL construction is verified here.
//

import Foundation

nonisolated enum CardDetailURLMapping {

    /// ASCII decimal digits — the minimal "contains a dialable digit"
    /// check for phone rejection.
    private static let asciiDigits = CharacterSet(charactersIn: "0123456789")

    /// Builds a `tel:` URL from a phone-number display string.
    /// Returns nil for empty/whitespace-only values AND for non-empty
    /// values containing no dialable digit (invalid input must never
    /// initiate a call). Visual separators (spaces, dashes,
    /// parentheses) are preserved per RFC 3966.
    static func phoneURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.rangeOfCharacter(from: asciiDigits) != nil else {
            return nil
        }
        return URL(string: "tel:\(trimmed)")
    }

    /// Builds a `mailto:` URL from an email address string.
    /// Returns nil for empty/whitespace-only values AND for non-empty
    /// values that fail the basic structural check: exactly one '@',
    /// a non-empty local part, no whitespace, and a domain with at
    /// least one dot and a non-empty TLD (invalid input must never
    /// open Mail).
    static func emailURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              !parts[1].isEmpty,
              trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
        else { return nil }

        let domain = String(parts[1])
        guard domain.contains("."),
              !domain.hasPrefix("."),
              !domain.hasSuffix(".")
        else { return nil }

        return URL(string: "mailto:\(trimmed)")
    }

    /// Builds a safe browser URL from a website string. If the
    /// value already has an http:// or https:// scheme, it is
    /// used as-is. Otherwise, if the value carries an explicit
    /// non-web scheme (e.g. `ftp://…`, `file://…`), it is REJECTED
    /// (nil); a bare domain is upgraded to https://.
    /// Returns nil for empty/whitespace-only values or unbuildable
    /// URLs.
    static func websiteURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let withScheme: String
        let lower = trimmed.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            withScheme = trimmed
        } else if hasExplicitNonWebScheme(lower) {
            // An explicit `scheme://` prefix that is not http/https is
            // rejected rather than silently upgraded to `https://…`.
            return nil
        } else {
            withScheme = "https://\(trimmed)"
        }
        guard let url = URL(string: withScheme),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return url
    }

    /// True when `lowercased` starts with an explicit `scheme://` whose
    /// scheme is not http/https (e.g. `ftp://`, `file://`). A bare
    /// host/port such as `example.com:8080` has no `://` and is NOT
    /// considered an explicit scheme (it is upgraded to https://).
    private static func hasExplicitNonWebScheme(_ lowercased: String) -> Bool {
        guard let separator = lowercased.range(of: "://") else { return false }
        let prefix = lowercased[lowercased.startIndex..<separator.lowerBound]
        guard let first = prefix.first, first.isLetter else { return false }
        return prefix.allSatisfy { character in
            character.isLetter || character.isNumber
                || character == "+" || character == "-" || character == "."
        }
    }
}
