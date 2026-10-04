//
//  GroupManagementView.swift
//  SimCamCard
//
//  Week 4 Increment 7 — P09 Group Management (T16 Group / Tag).
//
//  Spec sources:
//   - spec/page-inventory.md P09 Group Management
//   - spec/state-inventory.md S07 Group / Tag
//   - spec/reference-tests.md T16
//   - Evidence: evidence/screenshots/REF-group-01-select-card.png,
//     REF-group-02-create-dialog.png, REF-group-03-assigned.png,
//     REF-group-04-list.png, REF-group-05-filtered-list.png,
//     REF-group-06-delete-confirmation.png, REF-group-07-after-delete-empty.png
//
//  Reference observations → UI mapping:
//   - REF-group-01: card-selection screen with "已选 N 张" header,
//     per-card checkmarks, bottom "添加到分组 (N)" button.
//   - REF-group-02: "添加到分组" dialog with 新建分组 option and
//     未分组 row; 新建分组 triggers a small input dialog.
//   - REF-group-04: group list page with "新建分组" entry at top,
//     followed by 我的分组 rows showing name + count.
//   - REF-group-05: tapping a group row shows a filtered card list.
//   - REF-group-06: delete confirmation dialog "删除分组" with
//     取消 / 确认删除 buttons.
//   - REF-group-07: after delete, empty state "你还未创建分组".
//
//  State ownership: the shared CardHolderViewModel owns all state.
//  This View holds no cards, groups, or selection copies.
//

import SwiftUI

struct GroupManagementView: View {

    /// Shared Holder state owner (group catalog, selection, filter).
    @Bindable var viewModel: CardHolderViewModel

    /// Forwarded to BusinessCardRow for real session-saved thumbnails.
    let imageStore: (any ImageAssetStore)?

    @Environment(\.dismiss) private var dismiss

    /// Local UI state: which sub-screen to show.
    @State private var phase: Phase = .groupList

    /// Whether the create-group alert is showing.
    @State private var showCreateAlert = false

    /// Whether the delete-confirmation alert is showing.
    @State private var showDeleteAlert = false

    /// Group pending deletion.
    @State private var groupToDelete: CardTag?

    enum Phase {
        case groupList
        case selectingCards
    }

    var body: some View {
        Group {
            switch phase {
            case .groupList:
                groupListContent
            case .selectingCards:
                cardSelectionContent
            }
        }
        .navigationTitle("分组")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if phase == .selectingCards {
                    Button("取消") {
                        viewModel.clearGroupCardSelection()
                        phase = .groupList
                    }
                    .accessibilityIdentifier("group-selection-cancel")
                }
            }
        }
        .alert("新建分组", isPresented: $showCreateAlert) {
            TextField("请输入分组名称", text: $viewModel.pendingGroupName)
                .accessibilityIdentifier("group-name-field")
            Button("取消", role: .cancel) {
                viewModel.pendingGroupName = ""
            }
            Button("完成") {
                Task {
                    await viewModel.createGroup(named: viewModel.pendingGroupName)
                    // After creating from selection phase, return to list.
                    if phase == .selectingCards {
                        phase = .groupList
                    }
                }
            }
            .accessibilityIdentifier("group-create-confirm")
        }
        .alert("删除分组", isPresented: $showDeleteAlert, presenting: groupToDelete) { group in
            Button("取消", role: .cancel) {
                groupToDelete = nil
            }
            Button("确认删除", role: .destructive) {
                Task {
                    await viewModel.deleteGroup(id: group.id)
                    groupToDelete = nil
                }
            }
            .accessibilityIdentifier("group-delete-confirm")
        } message: { group in
            Text("删除后分组不可恢复，名片将保留在名片夹。确认删除？")
        }
    }

    // MARK: - Group list (REF-group-04)

    @ViewBuilder
    private var groupListContent: some View {
        List {
            // "新建分组" entry — always visible (REF-group-04 top row).
            Button {
                viewModel.beginGroupSelection()
                phase = .selectingCards
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .foregroundStyle(.blue)
                    Text("新建分组")
                        .foregroundStyle(.blue)
                }
            }
            .accessibilityIdentifier("group-create")

            // "我的分组" section header (REF-group-04).
            if !viewModel.groups.isEmpty {
                Section(header: Text("我的分组")) {
                    ForEach(viewModel.groups) { group in
                        groupRow(group)
                    }
                }
            }

            // Empty state (REF-group-07).
            if viewModel.groups.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 40)
                        Image(systemName: "person.2")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("你还未创建分组")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer().frame(height: 40)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("group-empty")
                }
            }
        }
        .accessibilityIdentifier("group-management")
    }

    // MARK: - Group row (REF-group-04 row style)

    @ViewBuilder
    private func groupRow(_ group: CardTag) -> some View {
        HStack {
            Button {
                viewModel.selectGroup(group.id)
                dismiss()
            } label: {
                HStack {
                    Text(group.name)
                        .foregroundStyle(.primary)
                    Text("(\(viewModel.cardCount(in: group.id)))")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("group-row-\(group.id.uuidString)")

            Spacer()

            Button {
                groupToDelete = group
                showDeleteAlert = true
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除 \(group.name)")
            .accessibilityIdentifier("group-delete-\(group.id.uuidString)")

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Card selection (REF-group-01)

    @ViewBuilder
    private var cardSelectionContent: some View {
        VStack(spacing: 0) {
            // Header: "已选 N 张" (REF-group-01).
            HStack {
                Text("已选 \(viewModel.groupCardSelection.count) 张")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            // Card list with checkmarks.
            List(viewModel.cards) { card in
                Button {
                    viewModel.toggleGroupCardSelection(card.id)
                } label: {
                    HStack {
                        Image(systemName: viewModel.groupCardSelection.contains(card.id)
                              ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(viewModel.groupCardSelection.contains(card.id)
                                             ? .blue : .secondary)
                        BusinessCardRow(card: card, imageStore: imageStore)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("group-card-select-\(card.id.uuidString)")
            }

            // Bottom button: "添加到分组 (N)" (REF-group-01).
            Button {
                showCreateAlert = true
            } label: {
                Text("添加到分组 (\(viewModel.groupCardSelection.count))")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.groupCardSelection.isEmpty
                                  ? Color.gray : Color.blue)
                    )
            }
            .disabled(viewModel.groupCardSelection.isEmpty)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .accessibilityIdentifier("group-create")
        }
    }
}

#if DEBUG

#Preview("Group Management") {
    let viewModel = CardHolderViewModel(
        repository: InMemoryBusinessCardRepository(
            initialCards: MockBusinessCards.all
        ),
        groupRepository: InMemoryCardGroupRepository()
    )
    return NavigationStack {
        GroupManagementView(viewModel: viewModel, imageStore: nil)
    }
    .task { await viewModel.loadHolderData() }
}

#endif
