//
//  BusinessCardMaterializer.swift
//  SimCamCard
//
//  Week 4 Increment 4 (T12 calibration) — pure deterministic mapping
//  from the corrected intermediate record to the final BusinessCard.
//
//  ScanViewModel owns the ORCHESTRATION only (resolve draft → persist
//  image assets → generate final identities → materialize →
//  repository.save → SaveState). THIS type owns the final-domain
//  mapping exclusively: no I/O, no state, no clock, and NO implicit
//  UUID()/Date() calls — the final card UUID, the per-phone final
//  UUIDs, the image references and the timestamp are ALL passed in, so
//  the mapping is fully deterministic: the same complete inputs always
//  produce the same BusinessCard, directly testable with fixed values.
//
//  Identity rule: the final BusinessCard is a NEW domain aggregate. It
//  inherits kind + value from the corrected intermediate phones, but
//  every final PhoneNumber receives the caller-provided FRESH domain
//  UUID (one per corrected phone, aligned by index) — the draft's
//  edit-row ids and the structured intermediate PhoneNumber.ids never
//  leak into the persisted record.
//
//  Raw OCR preservation: rawOCRText is the original
//  draft.source.ocrResult.rawText, carried through untouched.
//
//  Corrected-field projection comes from `draft.correctedFields`:
//  blank scalars become nil, blank phone/email rows are dropped,
//  phone kinds are preserved, `unclassifiedText` is carried through
//  unchanged. No semantic correction happens here.
//

import Foundation

nonisolated enum BusinessCardMaterializer: Sendable {

    /// Maps a corrected RecognitionDraft to the final BusinessCard.
    ///
    /// - Parameters:
    ///   - draft: the corrected intermediate record.
    ///   - cardID: the final aggregate's stable domain identity.
    ///   - originalImageReference / processedImageReference: real
    ///     resolvable asset tokens persisted by the orchestrator BEFORE
    ///     the card is written.
    ///   - timestamp: the single creation/update instant; the materializer
    ///     never reads the clock.
    ///   - finalPhoneIDs: one fresh domain UUID per corrected phone,
    ///     aligned by index. Must count-match the corrected phones —
    ///     identity allocation is the orchestrator's responsibility.
    static func materialize(
        draft: RecognitionDraft,
        cardID: UUID,
        originalImageReference: String,
        processedImageReference: String,
        timestamp: Date,
        finalPhoneIDs: [UUID]
    ) -> BusinessCard {
        let corrected = draft.correctedFields
        precondition(
            finalPhoneIDs.count == corrected.phones.count,
            "finalPhoneIDs must align 1:1 with corrected phones "
            + "(\(finalPhoneIDs.count)) vs \(corrected.phones.count))"
        )

        return BusinessCard(
            id: cardID,
            originalImageReference: originalImageReference,
            processedImageReference: processedImageReference,
            rawOCRText: draft.source.ocrResult.rawText,
            name: corrected.name,
            company: corrected.company,
            jobTitle: corrected.jobTitle,
            website: corrected.website,
            address: corrected.address,
            phones: zip(corrected.phones, finalPhoneIDs).map { phone, finalID in
                // Only kind + value are inherited; identity is injected.
                PhoneNumber(id: finalID, kind: phone.kind, value: phone.value)
            },
            emails: corrected.emails,
            createdAt: timestamp,
            updatedAt: timestamp
        )
    }
}
