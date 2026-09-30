//
//  CardDetailFieldRow.swift
//  SimCamCard
//
//  A single structured-field row on the read-only Card Detail page (P07).
//
//  Spec sources:
//   - spec/reference-tests.md T13 Detail
//   - Evidence: REF-detail-03-after-edit-expanded.png (field rows with
//     SF-symbol-style leading icons, primary value and a secondary kind
//     label such as 手机 / 工作电话 / 工作邮箱 / 公司地址 / 首页)
//
//  Layout:
//   - leading secondary-colored SF Symbol
//   - vertical stack: field value (primary) + field label (caption,
//     secondary)
//
//  This is a stateless presentational row. Absent fields are never
//  rendered at all — the caller (CardDetailView) decides which rows exist
//  based on the Domain Model, so missing data is not fabricated and no
//  empty placeholder rows are shown (spec/data-model.md §Missing-field
//  rule; T20 Card 004 minimal-card negative case).
//

import SwiftUI

struct CardDetailFieldRow: View {

    /// SF Symbol name for the leading icon.
    let systemImage: String

    /// Primary field value, e.g. "+86 138 0013 8000".
    let value: String

    /// Secondary field label, e.g. "手机" / "工作电话" / "邮箱" /
    /// "公司地址" / "首页".
    let label: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.body)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
