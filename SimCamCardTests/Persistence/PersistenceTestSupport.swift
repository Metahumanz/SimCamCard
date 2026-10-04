//
//  PersistenceTestSupport.swift
//  SimCamCardTests
//
//  Shared deterministic fixtures for the T18 persistence tests.
//
//  Every on-disk test runs in its OWN freshly-created temp directory
//  (unique per test) and removes it afterwards. Tests never touch the
//  real Application Support container.
//

import Foundation
@testable import SimCamCard

enum PersistenceTestSupport {

    /// Creates and returns a unique empty temp directory for one test.
    static func makeUniqueTempDirectory(label: String = "simcamcard-w4i9") throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(label)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Best-effort recursive cleanup of a test temp directory.
    static func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// A maximum-information card exercising EVERY BusinessCard field:
    /// 4 phone kinds, 2 emails, 1 tag, 1 note, raw OCR text, website,
    /// address, both image references (intentionally containing
    /// spaces/slashes/Unicode to prove reference tokens are stored
    /// verbatim in JSON and only encoded for asset filenames) and
    /// sub-millisecond-precision timestamps (three DISTINCT values,
    /// none aligned to whole milliseconds — pins lossless Date
    /// round-trip through JSON).
    static func makeMaxInfoCard() -> BusinessCard {
        BusinessCard(
            id: UUID(uuidString: "A1B2C3D4-0001-0001-0001-000000000001")!,
            originalImageReference: "card/001 原图+α",
            processedImageReference: "card/001 processed β",
            rawOCRText: "上海智云科技有限公司\n张伟\n产品总监 | Product Director",
            name: "张伟",
            company: "上海智云科技有限公司",
            jobTitle: "高级产品总监 | Senior Product Director",
            website: "www.zhiyuntech.com",
            address: "上海市浦东新区世纪大道100号 200120",
            phones: [
                PhoneNumber(
                    id: UUID(uuidString: "B1B2C3D4-0001-0001-0001-000000000001")!,
                    kind: .mobile, value: "+86 138 0013 8000"
                ),
                PhoneNumber(
                    id: UUID(uuidString: "B1B2C3D4-0001-0001-0001-000000000002")!,
                    kind: .office, value: "+86 21 5555 1234"
                ),
                PhoneNumber(
                    id: UUID(uuidString: "B1B2C3D4-0001-0001-0001-000000000003")!,
                    kind: .fax, value: "+86 21 5666 7799"
                ),
                PhoneNumber(
                    id: UUID(uuidString: "B1B2C3D4-0001-0001-0001-000000000004")!,
                    kind: .other, value: "400-000-0000"
                ),
            ],
            emails: ["wei.zhang@zhiyuntech.com", "zhangwei@example.cn"],
            tags: [
                CardTag(
                    id: UUID(uuidString: "C1B2C3D4-0001-0001-0001-000000000001")!,
                    name: "客户"
                )
            ],
            notes: [
                CardNote(
                    id: UUID(uuidString: "D1B2C3D4-0001-0001-0001-000000000001")!,
                    text: "跟进客户：下周回访",
                    createdAt: Date(timeIntervalSinceReferenceDate: 123_456_789.123_456_7)
                )
            ],
            createdAt: Date(timeIntervalSinceReferenceDate: 765_432_109.246_813_5),
            updatedAt: Date(timeIntervalSinceReferenceDate: 987_654_321.135_792_4)
        )
    }

    /// Deterministic bytes used for image asset round-trip checks.
    static let originalImageBytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, 255])
    static let processedImageBytes = Data([0xFF, 0xD8, 0xFF, 0xE0, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
}
