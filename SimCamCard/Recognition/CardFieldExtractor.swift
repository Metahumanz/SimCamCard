//
//  CardFieldExtractor.swift
//  SimCamCard
//
//  Week 4 Increment 1 — deterministic local structured field
//  extraction from preserved raw OCR lines (T08/T09/T10 core).
//
//  Design:
//   - Pure, deterministic, local. No network / LLM / cloud, no
//     randomness, no dataset-ID knowledge, no cross-card memory.
//     The same [OCRLine] input always yields the same result.
//   - Two phases:
//       Phase A — high-confidence typed tokens (emails, websites,
//                 labelled/format phones, labelled address).
//       Phase B — semantic text fields (company, job title, name)
//                 chosen ONLY from the lines Phase A did not claim.
//   - Classification uses internal normalized copies (lowercase /
//     digits-only / keyword match). Returned values preserve the OCR
//     text's case, punctuation and phone formatting; only field
//     labels and surrounding whitespace are removed.
//   - No OCR correction: a Vision mis-read such as 邮箱 → "邮稍" is
//     never repaired; the legal email token is still classified.
//   - No fabrication: website is never inferred from an email
//     domain, address from an area code, etc. (T09).
//

import Foundation

/// Synchronous deterministic extractor. Parsing is pure CPU value
/// work with no suspension points, so the requirement is not async.
nonisolated protocol CardFieldExtracting: Sendable {
    func extract(from result: CardOCRResult) -> StructuredRecognitionResult
}

nonisolated struct CardFieldExtractor: CardFieldExtracting {

    init() {}

    func extract(from result: CardOCRResult) -> StructuredRecognitionResult {
        let fields = Parser(texts: result.lines.map(\.text)).parse()
        return StructuredRecognitionResult(ocrResult: result, fields: fields)
    }
}

// MARK: - Parser

nonisolated private struct Parser {

    private let texts: [String]

    init(texts: [String]) {
        self.texts = texts
    }

    func parse() -> StructuredCardFields {
        var consumed = Array(repeating: false, count: texts.count)

        var emails: [String] = []
        var phones: [PhoneNumber] = []
        var website: String?
        var address: String?

        // ---- Phase A: high-confidence typed fields ----

        for (index, text) in texts.enumerated() {
            guard !consumed[index] else { continue }

            // Email tokens are recognized anywhere on the line, even
            // when the label itself is OCR-garbled (e.g. "邮稍
            // Email: x@y.com"). Ranges are masked before website
            // scanning so an email domain is never a website.
            let emailTokens = TokenPatterns.emails(in: text)
            if !emailTokens.isEmpty {
                for token in emailTokens where !emails.containsCaseInsensitive(token) {
                    emails.append(token)
                }
                consumed[index] = true
            }

            let label = LabelPatterns.label(in: text)

            if let label {
                switch label.family {
                case .email:
                    // Token extraction above already captured the
                    // address(es); the labelled line is a contact line.
                    consumed[index] = true

                case .website:
                    if let url = TokenPatterns.website(in: label.content) {
                        if website == nil { website = url }
                    } else if let url = TokenPatterns.website(in: text, maskingEmailsIn: text) {
                        if website == nil { website = url }
                    }
                    consumed[index] = true

                case .mobile, .office, .fax:
                    if let token = TokenPatterns.phone(in: label.content) {
                        phones.appendPhone(token, kind: label.family.phoneKind)
                    }
                    // Labelled contact line (even with a number the
                    // pattern did not accept) is never a name/company.
                    consumed[index] = true

                case .address:
                    address = collectAddress(
                        labelContent: label.content,
                        startIndex: index,
                        consumed: &consumed
                    )
                }
            } else if let url = TokenPatterns.website(in: text, maskingEmailsIn: text) {
                // Unlabelled URL token: classify and claim the line so
                // it can never become a name/company.
                if website == nil { website = url }
                consumed[index] = true
            }
        }

        // Unlabelled phone numbers on lines Phase A did not claim.
        // Deterministic format rule (NOT a length guess): a number is
        // only auto-classified as mobile when it is the Chinese mobile
        // international form (+86/86 followed by 1[3-9]xxxxxxxxx) or a
        // bare domestic 1[3-9]xxxxxxxxx on a line with no "+" prefix.
        // Every other unlabelled number is honestly classified .other.
        for (index, text) in texts.enumerated() {
            guard !consumed[index] else { continue }
            guard let token = TokenPatterns.phone(in: text) else { continue }
            let kind: PhoneNumber.Kind = TokenPatterns.looksLikeChineseMobile(token)
                ? .mobile
                : .other
            phones.appendPhone(token, kind: kind)
            consumed[index] = true
        }

        // ---- Phase B: semantic text fields ----

        let remaining = texts.indices.filter { !consumed[$0] }.map { texts[$0] }

        let company = SemanticHeuristics.company(in: remaining)
        let afterCompany = remaining.filter { $0 != company }

        let jobTitle = SemanticHeuristics.jobTitle(in: afterCompany)
        let afterTitle = afterCompany.filter { $0 != jobTitle }

        let name = SemanticHeuristics.name(in: afterTitle)
        let unclassified = afterTitle.filter { $0 != name }

        return StructuredCardFields(
            name: name,
            company: company,
            jobTitle: jobTitle,
            phones: phones.withDeterministicIDs(),
            emails: emails,
            website: website,
            address: address,
            unclassifiedText: unclassified
        )
    }

    /// Assembles address text from a labelled line plus deterministic
    /// immediately-following continuation lines. Continuation stops at
    /// the next labelled line, any contact token, or a line that does
    /// not carry address-like evidence.
    private func collectAddress(
        labelContent: String,
        startIndex: Int,
        consumed: inout [Bool]
    ) -> String {
        var pieces = [labelContent.trimmingCharacters(in: .whitespacesAndNewlines)]
        consumed[startIndex] = true

        var index = startIndex + 1
        while index < texts.count {
            let line = texts[index]
            if consumed[index]
                || LabelPatterns.label(in: line) != nil
                || !TokenPatterns.emails(in: line).isEmpty
                || TokenPatterns.website(in: line, maskingEmailsIn: line) != nil
                || TokenPatterns.phone(in: line) != nil
                || !TokenPatterns.looksLikeAddressContinuation(line) {
                break
            }
            pieces.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
            consumed[index] = true
            index += 1
        }

        return pieces
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - Label patterns

nonisolated private enum FieldFamily: Equatable {
    case mobile
    case office
    case fax
    case email
    case website
    case address

    var phoneKind: PhoneNumber.Kind {
        switch self {
        case .mobile: .mobile
        case .office: .office
        case .fax: .fax
        default: .other
        }
    }
}

nonisolated private struct LabelMatch: Equatable {
    let family: FieldFamily
    let content: String
}

nonisolated private enum LabelPatterns {

    /// Keyword tables for one label family. Bilingual cards print a
    /// CJK + latin pair ("手机 Mobile："), so up to two same-family
    /// tokens are accepted. Longer latin words are listed first so
    /// alternation prefers "Telephone" over "T".
    private struct FamilyTable {
        let family: FieldFamily
        let cn: [String]
        let en: [String]
    }

    private static let tables: [FamilyTable] = [
        FamilyTable(family: .mobile,
                    cn: ["手机号", "手机", "移动电话", "移动"],
                    en: ["Mobile", "Cell", "Mob", "Cel", "M"]),
        FamilyTable(family: .office,
                    cn: ["座机", "电话"],
                    en: ["Telephone", "Phone", "Office", "Tel", "T"]),
        FamilyTable(family: .fax,
                    cn: ["传真"],
                    en: ["Fax", "F"]),
        FamilyTable(family: .email,
                    cn: ["电子邮箱", "邮箱", "电子邮件", "邮件", "电邮"],
                    en: ["E-mail", "Email", "Mail", "E"]),
        FamilyTable(family: .website,
                    cn: ["网址", "网站"],
                    en: ["Website", "Web", "URL", "W"]),
        FamilyTable(family: .address,
                    cn: ["地址"],
                    en: ["Address", "Addr", "Add", "A"]),
    ]

    static func label(in line: String) -> LabelMatch? {
        for table in tables {
            if let match = matchFamily(line, table: table) {
                return match
            }
        }
        return nil
    }

    private static func matchFamily(_ line: String, table: FamilyTable) -> LabelMatch? {
        var index = line.startIndex
        var matchedTokens = 0

        // Up to two same-family label tokens (bilingual pairs).
        for _ in 0..<2 {
            while index < line.endIndex,
                  line[index] == " " || line[index] == "\t" || line[index] == "\u{3000}" {
                index = line.index(after: index)
            }
            guard index < line.endIndex else { break }

            let rest = String(line[index...])
            var consumedCount: Int?
            var isSingleLatinLetter = false

            if let keyword = table.cn.first(where: { rest.hasPrefix($0) }) {
                consumedCount = keyword.count
            } else if let keyword = matchLatinPrefix(rest, words: table.en) {
                consumedCount = keyword.count
                isSingleLatinLetter = keyword.count == 1
            }

            guard let count = consumedCount else { break }

            // One-letter latin labels ("M:", "T:", "F:") are only
            // accepted when immediately followed by a colon — this
            // prevents "Manager" / "Tech" from becoming labels.
            if isSingleLatinLetter {
                var probe = line.index(index, offsetBy: count)
                while probe < line.endIndex,
                      line[probe] == " " || line[probe] == "\t" || line[probe] == "\u{3000}" {
                    probe = line.index(after: probe)
                }
                guard probe < line.endIndex,
                      line[probe] == ":" || line[probe] == "：" else { break }
            }

            index = line.index(index, offsetBy: count)
            matchedTokens += 1
        }

        guard matchedTokens > 0 else { return nil }

        while index < line.endIndex,
              line[index] == " " || line[index] == "\t" || line[index] == "\u{3000}" {
            index = line.index(after: index)
        }
        if index < line.endIndex, line[index] == ":" || line[index] == "：" {
            index = line.index(after: index)
        }
        while index < line.endIndex,
              line[index] == " " || line[index] == "\t" || line[index] == "\u{3000}" {
            index = line.index(after: index)
        }

        let content = String(line[index...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return nil }
        return LabelMatch(family: table.family, content: content)
    }

    /// Latin keywords must end on a non-alphanumeric boundary so
    /// e.g. "Mail" cannot match inside "Marketing".
    private static func matchLatinPrefix(_ text: String, words: [String]) -> String? {
        let lower = text.lowercased()
        for word in words {
            let prefix = word.lowercased()
            guard lower.hasPrefix(prefix) else { continue }
            let end = lower.index(lower.startIndex, offsetBy: prefix.count)
            if end == lower.endIndex { return word }
            let next = lower[end]
            if !(next.isLetter || next.isNumber) { return word }
        }
        return nil
    }
}

// MARK: - Token patterns

nonisolated private enum TokenPatterns {

    // MARK: Email
    private static let emailRegex = try! NSRegularExpression(
        pattern: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
    )

    static func emails(in text: String) -> [String] {
        regexMatches(emailRegex, in: text).compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }

    // MARK: Website
    // http(s):// or www. prefixed URL tokens only. Bare domains are
    // intentionally NOT recognized (and email ranges are masked when
    // scanning the same text), so T09 card-002 cannot gain a
    // fabricated website.
    private static let websiteRegex = try! NSRegularExpression(
        pattern: #"(?:https?://|www\.)[^\s，,；;、）)】」』]+"#
    )

    static func website(in text: String, maskingEmailsIn maskedSource: String? = nil) -> String? {
        var haystack = text
        if maskedSource == text {
            for range in regexMatches(emailRegex, in: text)
                .compactMap({ Range($0.range, in: text) })
                .sorted(by: { $0.lowerBound > $1.lowerBound }) {
                let replacement = String(repeating: " ", count: text[range].count)
                haystack.replaceSubrange(range, with: replacement)
            }
        }
        guard let match = regexMatches(websiteRegex, in: haystack).first,
              let range = Range(match.range, in: haystack) else { return nil }
        var token = String(haystack[range])
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,。"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }

    // MARK: Phone
    // A digit-bounded run of digits/separators/parens/+ with at least
    // 7 digits. Only applied to lines the parser has already decided
    // are phone candidates, so a strict digit-rich token is safe.
    private static let phoneRegex = try! NSRegularExpression(
        pattern: #"\+?[0-9][0-9\s\-().]{5,}[0-9]"#
    )

    static func phone(in text: String) -> String? {
        for match in regexMatches(phoneRegex, in: text) {
            guard let range = Range(match.range, in: text) else { continue }
            let token = String(text[range]).trimmingCharacters(
                in: CharacterSet(charactersIn: " \t-().")
            )
            if token.filter(\.isNumber).count >= 7 {
                return token
            }
        }
        return nil
    }

    /// Chinese mobile format classifier (NOT a length heuristic):
    /// digits must end in 86 + 1[3-9] + 9 digits (international form,
    /// e.g. +86 138 0013 8000), or be exactly a bare domestic
    /// 1[3-9]xxxxxxxxx on a line carrying no "+" international prefix.
    /// All other unlabelled numbers remain `.other`.
    static func looksLikeChineseMobile(_ token: String) -> Bool {
        let digits = token.filter(\.isNumber)
        if digits.range(of: #"861[3-9][0-9]{9}$"#, options: .regularExpression) != nil {
            return true
        }
        if token.contains("+") { return false }
        return digits.range(of: #"^1[3-9][0-9]{9}$"#, options: .regularExpression) != nil
    }

    // MARK: Address continuation
    private static let addressEvidenceRegex = try! NSRegularExpression(
        pattern: #"[0-9]|号|路|街|弄|道|巷|区|市|省|镇|村|大厦|室|楼层?|栋|单元|St\.?|Street|Road|Rd\.?|Ave\.?|Avenue|Lane|Suite|Floor|Fl\.?|No\.?"#,
        options: [.caseInsensitive]
    )

    static func looksLikeAddressContinuation(_ text: String) -> Bool {
        regexMatches(addressEvidenceRegex, in: text).first != nil
    }

    private static func regexMatches(_ regex: NSRegularExpression, in text: String) -> [NSTextCheckingResult] {
        regex.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length))
    }
}

// MARK: - Semantic heuristics (Phase B)

nonisolated private enum SemanticHeuristics {

    // MARK: Company
    // Chinese keyword set follows the frozen plan §18 list.
    private static let companyCNRegex = try! NSRegularExpression(
        pattern: #"有限公司|集团|银行|大学|医院|事务所|研究院|工作室|公司"#
    )
    // English keyword set follows the frozen plan §18 list exactly
    // (plus the LLC spelling variant); deliberately NOT including
    // generic words such as "Solutions", which collide with real job
    // titles ("Solutions Architect").
    private static let companyENRegex = try! NSRegularExpression(
        pattern: #"\b(?:Inc\.?|Ltd\.?|Limited|LLC|L\.?L\.?C|GmbH|S\.?A\.?S|Studio|University|Hospital|Bank|Systems|Technologies|Technology|Labs|BioSystems)\b"#,
        options: .caseInsensitive
    )

    /// Native/canonical form is preferred on bilingual cards; the
    /// English counterpart stays in unclassified evidence.
    static func company(in remaining: [String]) -> String? {
        for line in remaining where regexMatches(companyCNRegex, in: line).first != nil {
            return line
        }
        for line in remaining where regexMatches(companyENRegex, in: line).first != nil {
            return line
        }
        return nil
    }

    // MARK: Job title
    private static let titleCNRegex = try! NSRegularExpression(
        pattern: #"总监|经理|工程师|建筑师|设计师|顾问|主任|教授|医生|主管|负责人"#
    )
    private static let titleENRegex = try! NSRegularExpression(
        pattern: #"\b(?:Director|Manager|Engineer|Architect|Designer|Consultant|Lead|President|Officer|CEO|CTO|CFO|COO|Product|Sales|Marketing|Specialist|Coordinator|Analyst|Developer|Partner|Founder)\b"#,
        options: .caseInsensitive
    )

    static func jobTitle(in remaining: [String]) -> String? {
        for line in remaining {
            if regexMatches(titleCNRegex, in: line).first != nil { return line }
            if regexMatches(titleENRegex, in: line).first != nil { return line }
        }
        return nil
    }

    // MARK: Name
    // Prefer a 2–4 CJK-character person name. A Vision-inserted space
    // ("张 伟") is tolerated for detection but the value is preserved
    // verbatim. A line combining the CJK name with its latin
    // counterpart ("何嘉怡 Jiayi He") yields the CJK prefix as the
    // canonical name; the full line remains unclassified evidence.
    // Otherwise accept a simple capitalized "Given Family" latin line.
    private static let cjkNameWithOptionalLatinRegex = try! NSRegularExpression(
        pattern: #"^\s*[\p{Han}]{2,4}(?:\s+[A-Za-z][A-Za-z.\-']*(?:\s+[A-Za-z][A-Za-z.\-']*)?)?\s*$"#
    )
    private static let leadingCJKNameRegex = try! NSRegularExpression(
        pattern: #"[\p{Han}]{2,4}"#
    )
    private static let bareCJKNameRegex = try! NSRegularExpression(
        pattern: #"^[\p{Han}]{2,4}$"#
    )
    private static let latinNameRegex = try! NSRegularExpression(
        pattern: #"^[A-Z][A-Za-z\-']+(?:\s+[A-Z]\.?)?\s+[A-Z][A-Za-z\-']+$"#
    )

    static func name(in remaining: [String]) -> String? {
        for line in remaining {
            let stripped = line.filter { !$0.isWhitespace }
            if fullRange(of: bareCJKNameRegex, in: stripped) != nil {
                return line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        for line in remaining
        where fullRange(of: cjkNameWithOptionalLatinRegex, in: line) != nil {
            if let match = regexMatches(leadingCJKNameRegex, in: line).first,
               let range = Range(match.range, in: line) {
                return String(line[range])
            }
        }

        for line in remaining where fullRange(of: latinNameRegex, in: line) != nil {
            return line
        }
        return nil
    }

    private static func fullRange(of regex: NSRegularExpression, in text: String) -> NSRange? {
        guard let match = regex.matches(in: text,
                                        range: NSRange(location: 0, length: (text as NSString).length)).first,
              match.range.length == (text as NSString).length else { return nil }
        return match.range
    }

    private static func regexMatches(_ regex: NSRegularExpression, in text: String) -> [NSTextCheckingResult] {
        regex.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length))
    }
}

// MARK: - Phone collection helpers

nonisolated private extension Array where Element == PhoneNumber {

    mutating func appendPhone(_ value: String, kind: PhoneNumber.Kind) {
        let digits = value.filter(\.isNumber)
        if contains(where: { $0.kind == kind && $0.value.filter(\.isNumber) == digits }) {
            return
        }
        append(PhoneNumber(id: PhoneIdentifier.placeholder, kind: kind, value: value))
    }

    /// Deterministic IDs by encounter position so repeated extraction
    /// of identical input is value-equal (including `PhoneNumber.id`).
    func withDeterministicIDs() -> [PhoneNumber] {
        enumerated().map { index, phone in
            PhoneNumber(id: PhoneIdentifier.id(index), kind: phone.kind, value: phone.value)
        }
    }
}

nonisolated private extension Array where Element == String {

    /// Exact-duplicate email removal, compared case-insensitively
    /// (domain part is case-insensitive); first OCR spelling wins.
    func containsCaseInsensitive(_ token: String) -> Bool {
        contains { $0.caseInsensitiveCompare(token) == .orderedSame }
    }
}

/// Parser-generated deterministic phone UUIDs: zero prefix +
/// UInt64(position + 1). These values never leave the extraction
/// pipeline intermediate in this increment.
nonisolated private enum PhoneIdentifier {
    static let placeholder = idRaw(0)

    static func id(_ index: Int) -> UUID { idRaw(UInt64(index + 1)) }

    /// `00000000-0000-0000-XXXX-XXXXXXXXXXXX` where the last 8 bytes
    /// hold the big-endian position value.
    private static func idRaw(_ value: UInt64) -> UUID {
        let hex = String(format: "%016llx", value)
        return UUID(uuidString:
            "00000000-0000-0000-\(hex.prefix(4))-\(hex.suffix(12))"
        )!
    }
}
