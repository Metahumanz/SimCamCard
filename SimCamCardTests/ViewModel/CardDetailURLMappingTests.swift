//
//  CardDetailURLMappingTests.swift
//  SimCamCardTests
//
//  Unit tests for CardDetailURLMapping (Final Delivery Phase 1.1 — B-01).
//
//  Tests the pure URL-construction functions:
//   - phoneURL: tel: scheme, visual separators preserved
//   - emailURL: mailto: scheme
//   - websiteURL: safe https upgrade, scheme validation
//
//  Invalid/empty values must return nil so the View never calls
//  openURL with a bad URL.
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("CardDetailURLMapping")
struct CardDetailURLMappingTests {

    // MARK: - phoneURL

    @Test("phoneURL builds tel: from valid number")
    func phoneURLValid() {
        let url = CardDetailURLMapping.phoneURL("+86 138 0013 8000")
        #expect(url != nil)
        #expect(url?.scheme == "tel")
        // URL(string:) percent-encodes spaces; the Phone app still
        // recognizes the number. Visual separators are preserved in the
        // source string and carried through the URL encoding.
        #expect(url?.absoluteString == "tel:+86%20138%200013%208000")
    }

    @Test("phoneURL preserves visual separators")
    func phoneURLSeparators() {
        let url = CardDetailURLMapping.phoneURL("+1 (415) 555-0184")
        #expect(url != nil)
        #expect(url?.absoluteString == "tel:+1%20(415)%20555-0184")
    }

    @Test("phoneURL returns nil for empty string")
    func phoneURLEmpty() {
        #expect(CardDetailURLMapping.phoneURL("") == nil)
    }

    @Test("phoneURL returns nil for whitespace-only string")
    func phoneURLWhitespace() {
        #expect(CardDetailURLMapping.phoneURL("   \n\t ") == nil)
    }

    // MARK: - emailURL

    @Test("emailURL builds mailto: from valid email")
    func emailURLValid() {
        let url = CardDetailURLMapping.emailURL("ting.zhou@yqedu.cn")
        #expect(url != nil)
        #expect(url?.scheme == "mailto")
        #expect(url?.absoluteString == "mailto:ting.zhou@yqedu.cn")
    }

    @Test("emailURL returns nil for empty string")
    func emailURLEmpty() {
        #expect(CardDetailURLMapping.emailURL("") == nil)
    }

    @Test("emailURL returns nil for whitespace-only string")
    func emailURLWhitespace() {
        #expect(CardDetailURLMapping.emailURL("  \n ") == nil)
    }

    // MARK: - websiteURL

    @Test("websiteURL prepends https:// for bare domain")
    func websiteURLBareDomain() {
        let url = CardDetailURLMapping.websiteURL("www.yqedu.cn")
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.absoluteString == "https://www.yqedu.cn")
    }

    @Test("websiteURL preserves existing https:// scheme")
    func websiteURLHttps() {
        let url = CardDetailURLMapping.websiteURL("https://example.com/path")
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.absoluteString == "https://example.com/path")
    }

    @Test("websiteURL preserves existing http:// scheme")
    func websiteURLHttp() {
        let url = CardDetailURLMapping.websiteURL("http://example.com")
        #expect(url != nil)
        #expect(url?.scheme == "http")
        #expect(url?.absoluteString == "http://example.com")
    }

    @Test("websiteURL returns nil for empty string")
    func websiteURLEmpty() {
        #expect(CardDetailURLMapping.websiteURL("") == nil)
    }

    @Test("websiteURL returns nil for whitespace-only string")
    func websiteURLWhitespace() {
        #expect(CardDetailURLMapping.websiteURL("  \n ") == nil)
    }

    @Test("websiteURL rejects non-http scheme")
    func websiteURLRejectsJavascript() {
        #expect(CardDetailURLMapping.websiteURL("javascript:alert(1)") == nil)
    }

    @Test("websiteURL rejects data: scheme")
    func websiteURLRejectsData() {
        #expect(CardDetailURLMapping.websiteURL("data:text/plain,hello") == nil)
    }

    // MARK: - Invalid-input handling (Phase 1.1 calibration)
    //
    // Frozen requirement: invalid OR missing values must never trigger a
    // system action. Non-empty garbage is invalid too, so it returns nil
    // exactly like an empty value — it must never be handed to openURL.

    @Test("phoneURL rejects a non-empty non-numeric value")
    func phoneURLRejectsNonNumeric() {
        #expect(CardDetailURLMapping.phoneURL("not-a-phone") == nil)
    }

    @Test("phoneURL rejects separators-only / letter-only values")
    func phoneURLRejectsSeparatorsAndLetters() {
        #expect(CardDetailURLMapping.phoneURL("()-") == nil)
        #expect(CardDetailURLMapping.phoneURL("abc def") == nil)
        #expect(CardDetailURLMapping.phoneURL("+++") == nil)
    }

    @Test("phoneURL still accepts a digit-bearing value with separators")
    func phoneURLAcceptsDigitBearingWithSeparators() {
        // Minimal digit check; punctuation in a real display number is
        // preserved per RFC 3966.
        let url = CardDetailURLMapping.phoneURL("(021) 5555-1234")
        #expect(url?.scheme == "tel")
        #expect(url?.absoluteString == "tel:(021)%205555-1234")
    }

    @Test("emailURL rejects a non-empty malformed value")
    func emailURLRejectsMalformed() {
        #expect(CardDetailURLMapping.emailURL("not-an-email") == nil)
    }

    @Test("emailURL rejects structurally invalid addresses")
    func emailURLRejectsStructuralCounterexamples() {
        #expect(CardDetailURLMapping.emailURL("a@@b.com") == nil)   // two @
        #expect(CardDetailURLMapping.emailURL("@b.com") == nil)     // empty local
        #expect(CardDetailURLMapping.emailURL("a@") == nil)         // empty domain
        #expect(CardDetailURLMapping.emailURL("a b@c.com") == nil)  // whitespace
        #expect(CardDetailURLMapping.emailURL("a@b") == nil)        // no domain dot
        #expect(CardDetailURLMapping.emailURL("a@.com") == nil)     // empty host
        #expect(CardDetailURLMapping.emailURL("a@b.com.") == nil)   // empty TLD
    }

    @Test("emailURL still accepts a valid dotted-domain address")
    func emailURLStillAcceptsValid() {
        let url = CardDetailURLMapping.emailURL("ting.zhou@yqedu.cn")
        #expect(url?.scheme == "mailto")
        #expect(url?.absoluteString == "mailto:ting.zhou@yqedu.cn")
    }

    @Test("websiteURL rejects unsafe schemes regardless of case")
    func websiteURLRejectsUnsafeSchemeCaseInsensitive() {
        #expect(CardDetailURLMapping.websiteURL("JavaScript:alert(1)") == nil)
        #expect(CardDetailURLMapping.websiteURL("DaTa:text/plain,hello") == nil)
    }

    @Test("websiteURL rejects an explicit non-web scheme instead of upgrading it")
    func websiteURLRejectsNonWebScheme() {
        // Calibration B-01 finding (now fixed in CardDetailURLMapping):
        // a value like "ftp://example.com" used to be silently upgraded to
        // "https://ftp://example.com". An explicit non-web `scheme://`
        // prefix is now rejected.
        #expect(CardDetailURLMapping.websiteURL("ftp://example.com") == nil)
        #expect(CardDetailURLMapping.websiteURL("file:///etc/passwd") == nil)
        #expect(CardDetailURLMapping.websiteURL("javascript:void(0)") == nil)
    }

    @Test("websiteURL still upgrades a bare host:port (no explicit scheme)")
    func websiteURLBareHostPortStaysUpgraded() {
        // "example.com:8080" has no `://`, so it is a bare host:port and
        // must still be upgraded to https rather than rejected.
        let url = CardDetailURLMapping.websiteURL("example.com:8080")
        #expect(url?.scheme == "https")
        #expect(url?.absoluteString == "https://example.com:8080")
    }
}
