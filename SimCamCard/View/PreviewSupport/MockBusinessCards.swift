//
//  MockBusinessCards.swift
//  SimCamCard
//
//  Deterministic mock fixtures for DEBUG / Preview / UI-test use only.
//
//  Spec sources:
//   - spec/data-model.md §BusinessCard (minimum field table),
//     §Multi-value observation (phones[] with kind = mobile / office / fax)
//     §Missing-field rule (Card 002 has no website; Card 004 minimal)
//   - dataset/ground-truth/card-001.json (full bilingual, multi-phone)
//   - dataset/ground-truth/card-002.json (missing website)
//   - dataset/ground-truth/card-004.json (minimal: name + mobile only)
//
//  Constraints (Week 2 Increment 4 brief):
//   - DEBUG / Preview / UI-test only. NOT Release / default runtime data.
//   - Fixed UUIDs (no UUID()), fixed Dates (no Date.now),
//     fixed image reference tokens (no random content).
//   - Few readable cards with representative ground-truth field shapes —
//     does not hard-code all 34 dataset cards.
//   - Field shapes follow the frozen Domain Model (no new fields invented).
//
//  The normal App launch path does NOT inject these fixtures. UI tests opt
//  in via the `-SimCamCardFixture <mode>` launch argument, parsed in
//  `SimCamCardFixture.swift`. Release builds compile out fixture injection
//  entirely (see SimCamCardFixture.swift `#else` branch).
//

#if DEBUG
import Foundation

enum MockBusinessCards {

    // MARK: - Fixed identifiers and timestamps
    //
    // Deterministic across runs so tests can assert by UUID and by Date
    // without depending on UUID() / Date.now.
    //
    // UUIDs are mapped to the ground-truth card-001 / card-002 / card-004
    // IDs they are derived from (only the suffix differs).

    /// `00000000-0000-0000-0000-000000000001` — fixture for card-001.
    static let card001ID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// `00000000-0000-0000-0000-000000000002` — fixture for card-002.
    static let card002ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    /// `00000000-0000-0000-0000-000000000004` — fixture for card-004.
    static let card004ID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

    /// Fixed creation/update timestamp for all mock cards.
    /// `Date(timeIntervalSince1970: 1735689600)` = 2025-01-01 00:00:00 UTC.
    /// Same value for `createdAt` and `updatedAt` — fixtures are immutable
    /// test seeds and do not simulate edit history.
    static let fixedDate = Date(timeIntervalSince1970: 1735689600)

    // MARK: - Cards

    /// Card-001 fixture: full bilingual card with multi-phone (mobile + office),
    /// email, website, address. Mirrors `dataset/ground-truth/card-001.json`.
    ///
    /// Matches the card shown in `REF-card-holder-02-after-save.png`
    /// (张伟 / 上海智云科技有限公司 / 产品总监 | Product Director).
    static let card001 = BusinessCard(
        id: card001ID,
        originalImageReference: "mock-card-001-original",
        processedImageReference: "mock-card-001-processed",
        rawOCRText: nil,
        name: "张伟",
        company: "上海智云科技有限公司",
        jobTitle: "产品总监 | Product Director",
        website: "www.zhiyuntech.com",
        address: "上海市浦东新区世纪大道100号 200120",
        phones: [
            PhoneNumber(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                       kind: .mobile, value: "+86 138 0013 8000"),
            PhoneNumber(id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
                       kind: .office, value: "+86 21 5555 1234"),
        ],
        emails: ["wei.zhang@zhiyuntech.com"],
        tags: [],
        notes: [],
        createdAt: fixedDate,
        updatedAt: fixedDate
    )

    /// Card-002 fixture: missing-website case. Mirrors
    /// `dataset/ground-truth/card-002.json` (T09 no-fabrication baseline).
    static let card002 = BusinessCard(
        id: card002ID,
        originalImageReference: "mock-card-002-original",
        processedImageReference: "mock-card-002-processed",
        rawOCRText: nil,
        name: "李娜",
        company: "上海智云科技有限公司",
        jobTitle: "市场总监 | Marketing Director",
        website: nil,
        address: "上海市浦东新区世纪大道188号 200120",
        phones: [
            PhoneNumber(id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
                       kind: .mobile, value: "+86 139 1234 5678"),
            PhoneNumber(id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
                       kind: .office, value: "+86 21 6888 2468"),
        ],
        emails: ["lina.li@zhiyuntech.com"],
        tags: [],
        notes: [],
        createdAt: fixedDate,
        updatedAt: fixedDate
    )

    /// Card-004 fixture: minimal card — only name + mobile. Mirrors
    /// `dataset/ground-truth/card-004.json` (T20 minimal-card exception).
    /// All other structured fields are nil; phones has a single mobile entry.
    static let card004 = BusinessCard(
        id: card004ID,
        originalImageReference: "mock-card-004-original",
        processedImageReference: "mock-card-004-processed",
        rawOCRText: nil,
        name: "张伟",
        company: nil,
        jobTitle: nil,
        website: nil,
        address: nil,
        phones: [
            PhoneNumber(id: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!,
                       kind: .mobile, value: "+86 138 0013 8000"),
        ],
        emails: [],
        tags: [],
        notes: [],
        createdAt: fixedDate,
        updatedAt: fixedDate
    )

    // MARK: - Fixture sets

    /// All three representative fixtures — multi-card populated state.
    /// Membership only; ordering is NOT a contract.
    static let all: [BusinessCard] = [card001, card002, card004]

    /// Single-card populated state — mirrors
    /// `REF-card-holder-02-after-save.png` (one card visible immediately
    /// after save).
    static let single: [BusinessCard] = [card001]
}
#endif
