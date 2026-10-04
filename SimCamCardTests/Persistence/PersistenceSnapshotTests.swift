//
//  PersistenceSnapshotTests.swift
//  SimCamCardTests
//
//  Unit tests for the T18 persistence DTO layer:
//   - deterministic Domain ↔ Snapshot round-trip preserves EVERY
//     BusinessCard field and identity (S10: corrected fields, tag,
//     notes, image references, timestamps);
//   - JSON document encode/decode (schemaVersion, dates persisted as
//     timeIntervalSinceReferenceDate Doubles for lossless Domain
//     round-trip) round-trips to an identical Domain value;
//   - phone-kind mapping is exhaustive and lossless.
//
//  The frozen Domain types are NOT Codable — only the persistence
//  snapshots are; these tests pin that boundary.
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("PersistenceSnapshots")
struct PersistenceSnapshotTests {

    // MARK: - Domain → Snapshot → Domain

    @Test("max-info card round-trips through snapshots field-for-field")
    func maxInfoCardSnapshotRoundTrip() {
        let card = PersistenceTestSupport.makeMaxInfoCard()

        let restored = BusinessCardSnapshot(card).businessCard()

        #expect(restored == card)
        // Explicit identity / multi-value assertions in addition to ==.
        #expect(restored.id == card.id)
        #expect(restored.phones.map(\.id) == card.phones.map(\.id))
        #expect(restored.phones.map(\.kind) == [.mobile, .office, .fax, .other])
        #expect(restored.phones.map(\.value) == card.phones.map(\.value))
        #expect(restored.emails == card.emails)
        #expect(restored.tags.map(\.id) == card.tags.map(\.id))
        #expect(restored.tags.map(\.name) == ["客户"])
        #expect(restored.notes.first?.id == card.notes.first?.id)
        #expect(restored.notes.first?.text == "跟进客户：下周回访")
        #expect(restored.notes.first?.createdAt == card.notes.first?.createdAt)
        #expect(restored.rawOCRText == card.rawOCRText)
        #expect(restored.originalImageReference == card.originalImageReference)
        #expect(restored.processedImageReference == card.processedImageReference)
        #expect(restored.createdAt == card.createdAt)
        #expect(restored.updatedAt == card.updatedAt)
    }

    @Test("nil optional fields and empty collections round-trip as absent/empty")
    func minimalCardSnapshotRoundTrip() {
        let card = BusinessCard(
            id: UUID(uuidString: "A1B2C3D4-0002-0002-0002-000000000002")!,
            originalImageReference: "min-original",
            processedImageReference: "min-processed",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        #expect(BusinessCardSnapshot(card).businessCard() == card)
    }

    // MARK: - JSON document round-trip

    @Test("cards JSON document preserves schema version and all fields")
    func cardsJSONDocumentRoundTrip() throws {
        let card = PersistenceTestSupport.makeMaxInfoCard()
        let document = BusinessCardStoreDocument(cards: [BusinessCardSnapshot(card)])

        let data = try PersistenceJSON.encoder.encode(document)
        let decoded = try PersistenceJSON.decoder.decode(
            BusinessCardStoreDocument.self, from: data
        )

        #expect(decoded.schemaVersion == BusinessCardStoreDocument.currentSchemaVersion)
        #expect(decoded.schemaVersion == 1)
        #expect(decoded.cards.count == 1)
        #expect(decoded.cards[0].businessCard() == card)
    }

    @Test("groups JSON document round-trips and carries an empty-group catalog")
    func groupsJSONDocumentRoundTrip() throws {
        let emptyGroup = CardTag(
            id: UUID(uuidString: "C1B2C3D4-0009-0009-0009-000000000009")!,
            name: "潜在客户"
        )
        let document = CardGroupStoreDocument(groups: [CardTagSnapshot(emptyGroup)])

        let data = try PersistenceJSON.encoder.encode(document)
        let decoded = try PersistenceJSON.decoder.decode(
            CardGroupStoreDocument.self, from: data
        )

        #expect(decoded.schemaVersion == 1)
        #expect(decoded.groups.map { $0.cardTag() } == [emptyGroup])
    }

    // MARK: - Exhaustive phone-kind mapping

    @Test("every domain phone kind maps losslessly through the snapshot kind")
    func phoneKindMappingIsExhaustive() throws {
        for kind in PhoneNumber.Kind.allCases {
            let snapshotKind = PhoneKindSnapshot(kind)
            #expect(PhoneNumber.Kind(snapshotKind) == kind)
        }
    }

    @Test("all snapshot phone kinds decode from stable raw strings")
    func phoneKindRawValuesAreStable() throws {
        #expect(try JSONDecoder().decode(PhoneKindSnapshot.self, from: Data("\"mobile\"".utf8)) == .mobile)
        #expect(try JSONDecoder().decode(PhoneKindSnapshot.self, from: Data("\"office\"".utf8)) == .office)
        #expect(try JSONDecoder().decode(PhoneKindSnapshot.self, from: Data("\"fax\"".utf8)) == .fax)
        #expect(try JSONDecoder().decode(PhoneKindSnapshot.self, from: Data("\"other\"".utf8)) == .other)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(PhoneKindSnapshot.self, from: Data("\"car\"".utf8))
        }
    }

    @Test("date codec is bit-exact for arbitrary sub-millisecond intervals")
    func dateCodecBitExactForArbitraryDoubles() throws {
        // The codec must round-trip the IEEE 754 Double itself —
        // including pre-reference-date (negative) and far-future
        // instants whose fractional part no date FORMATTER could
        // represent.
        let intervals: [Double] = [
            123_456_789.123_456_7,
            -1_234_567.890_123_4,
            7_200_000_000.000_000_1,
            42.000_000_1,
        ]
        for interval in intervals {
            let date = Date(timeIntervalSinceReferenceDate: interval)
            let data = try PersistenceJSON.encoder.encode([date])
            let restored = try PersistenceJSON.decoder.decode([Date].self, from: data)
            #expect(restored == [date])
            #expect(restored[0].timeIntervalSinceReferenceDate == interval)
        }
    }

    @Test("sub-millisecond timestamps round-trip JSON coding bit-exactly")
    func subMillisecondDatesSurviveJSON() throws {
        // Fixture dates are three DISTINCT non-millisecond-aligned
        // values (see PersistenceTestSupport.makeMaxInfoCard); ISO 8601
        // text would truncate them, the numeric Double codec must not.
        let card = PersistenceTestSupport.makeMaxInfoCard()
        let data = try PersistenceJSON.encoder.encode(BusinessCardSnapshot(card))
        let decoded = try PersistenceJSON.decoder.decode(BusinessCardSnapshot.self, from: data)
        let restored = decoded.businessCard()

        #expect(restored == card)
        #expect(restored.createdAt == card.createdAt)
        #expect(restored.updatedAt == card.updatedAt)
        #expect(restored.notes[0].createdAt == card.notes[0].createdAt)

        // Pin the on-disk representation: dates are JSON numbers
        // (timeIntervalSinceReferenceDate Doubles), not strings.
        let snapshotJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(snapshotJSON?["createdAt"] as? Double == card.createdAt.timeIntervalSinceReferenceDate)
        #expect(snapshotJSON?["updatedAt"] as? Double == card.updatedAt.timeIntervalSinceReferenceDate)
    }
}
