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
//   - Assignment §10: "Tap phone number; Tap email address; Tap website"
//     — phone/email/website rows carry a tap action that opens the
//     corresponding system URL (tel:/mailto:/https). Address rows have
//     no action (not in the assignment's must-tap list).
//
//  Layout:
//   - leading secondary-colored SF Symbol
//   - vertical stack: field value (primary) + field label (caption,
//     secondary)
//
//  When `action` is non-nil the content is wrapped in a Button with
//  `.buttonStyle(.plain)` so that each row is an independent tappable
//  control (same pattern as the action-strip buttons — avoids List-row
//  default `.automatic` which would run every button in a shared row).
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

    /// Optional tap action. When non-nil, the row is wrapped in a
    /// Button. Phone/email/website rows supply this; address and
    /// other non-tappable rows pass nil.
    let action: (() -> Void)?

    init(systemImage: String, value: String, label: String, action: (() -> Void)? = nil) {
        self.systemImage = systemImage
        self.value = value
        self.label = label
        self.action = action
    }

    var body: some View {
        if let action {
            Button(action: action) {
                rowContent
            }
            .foregroundStyle(.primary)
            .buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
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
