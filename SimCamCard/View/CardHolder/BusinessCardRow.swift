//
//  BusinessCardRow.swift
//  SimCamCard
//
//  Card Holder list row for a single BusinessCard (P01 populated state).
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder (populated list)
//   - spec/state-inventory.md S01 populated (one or more cards shown)
//   - spec/reference-tests.md T13 Detail (selecting a row opens Detail)
//   - Evidence: evidence/screenshots/REF-card-holder-02-after-save.png
//
//  Evidence-supported fields rendered (Week 2 scaffold):
//   - Name (primary, semibold)
//   - Job title · Company (secondary line)
//
//  As of Week 2 Increment 5 this row is embedded in a NavigationLink by
//  CardHolderView; tapping it pushes the read-only Card Detail page.
//
//  Week 4 Increment 4 (T12): when an ImageAssetStore is injected the row
//  renders the card's REAL processed-image thumbnail resolved from its
//  persisted `processedImageReference` (REF-card-holder-02-after-save.png).
//  Without a store (Previews, tests, fixture-seeded cards whose assets
//  were never captured) the row stays text-only — no fabricated
//  placeholder image is ever shown.
//
//  Deliberately still omitted:
//   - Three-dot per-row actions menu — per-row actions / context menu /
//     delete deferred.
//   - Favorites / avatar / company logo / swipe actions / context menus /
//     online enrichment — deferred.
//
//  State ownership:
//   - This View is stateless. The BusinessCard is passed in; the View
//     does not own or mutate a [BusinessCard] source of truth. The
//     thumbnail bytes are a UI-local presentation cache resolved from
//     the injected store; the store stays the single owner of assets.
//

import SwiftUI

struct BusinessCardRow: View {

    let card: BusinessCard

    /// Optional asset store used to resolve the card's real
    /// `processedImageReference` into thumbnail bytes (T12). Nil → the
    /// row renders text-only.
    let imageStore: (any ImageAssetStore)?

    /// UI-local presentation cache of the resolved thumbnail bytes.
    @State private var thumbnail: Data?

    init(card: BusinessCard, imageStore: (any ImageAssetStore)? = nil) {
        self.card = card
        self.imageStore = imageStore
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let thumbnail, let image = UIImage(data: thumbnail) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .accessibilityIdentifier("card-row-thumbnail")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.name ?? "未命名")
                    .font(.body.weight(.semibold))

                // Secondary line: job title · company. Skipped entirely
                // when both are nil (Card 004 minimal card → only name).
                if card.jobTitle != nil || card.company != nil {
                    Text(secondaryLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .task(id: card.processedImageReference) {
            guard let imageStore else { return }
            thumbnail = await imageStore.data(for: card.processedImageReference)
        }
    }

    /// Composes the secondary line as "jobTitle · company", omitting
    /// whichever structured field is nil. Both present → joined by " · ".
    /// One present → shown alone. Both nil → empty (caller skips line).
    private var secondaryLine: String {
        [card.jobTitle, card.company]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

#if DEBUG

#Preview("BusinessCardRow — full bilingual card") {
    List {
        BusinessCardRow(card: MockBusinessCards.card001)
            .accessibilityIdentifier("card-row-\(MockBusinessCards.card001.id.uuidString)")
    }
    .listStyle(.plain)
}

#Preview("BusinessCardRow — missing website (Card 002)") {
    List {
        BusinessCardRow(card: MockBusinessCards.card002)
            .accessibilityIdentifier("card-row-\(MockBusinessCards.card002.id.uuidString)")
    }
    .listStyle(.plain)
}

#Preview("BusinessCardRow — minimal card (Card 004)") {
    List {
        BusinessCardRow(card: MockBusinessCards.card004)
            .accessibilityIdentifier("card-row-\(MockBusinessCards.card004.id.uuidString)")
    }
    .listStyle(.plain)
}

#endif
