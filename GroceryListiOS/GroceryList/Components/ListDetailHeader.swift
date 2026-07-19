import SwiftUI

struct ListDetailHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let listName: String
    let lists: [GroceryList]
    var canClearCompleted: Bool = false
    var showCompletedItems: Bool = true
    var onBack: () -> Void
    var onSelectList: (GroceryList) -> Void
    var onShareList: () -> Void
    var onRenameList: () -> Void
    var onToggleCompletedVisibility: () -> Void
    var onClearCompleted: () -> Void
    var onDeleteList: () -> Void

    @State private var showListOptions = false

    private var usesStackedHeader: Bool {
        DynamicTypeLayout.usesStackedListHeader(dynamicTypeSize)
    }

    var body: some View {
        Group {
            if usesStackedHeader {
                stackedHeader
            } else {
                compactHeader
            }
        }
        .sheet(isPresented: $showListOptions) {
            ListOptionsSheet(
                showCompletedItems: showCompletedItems,
                canClearCompleted: canClearCompleted,
                onRename: {
                    showListOptions = false
                    onRenameList()
                },
                onToggleCompletedVisibility: {
                    showListOptions = false
                    onToggleCompletedVisibility()
                },
                onClearCompleted: {
                    showListOptions = false
                    onClearCompleted()
                },
                onDeleteList: {
                    showListOptions = false
                    onDeleteList()
                }
            )
        }
    }

    private var compactHeader: some View {
        HStack(alignment: .center, spacing: 4) {
            backButton
            listPickerLabel(lineLimit: 1)
                .frame(maxWidth: .infinity)
            shareButton
            moreButton
        }
        .frame(minHeight: 44)
    }

    private var stackedHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                backButton
                Spacer(minLength: 0)
                shareButton
                moreButton
            }
            listPickerLabel(lineLimit: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.ink)
                .frame(width: 44, height: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to lists")
    }

    private var shareButton: some View {
        Button(action: onShareList) {
            Image(systemName: AppIcons.share)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.ink)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share list")
    }

    private var moreButton: some View {
        Button {
            showListOptions = true
        } label: {
            Image(systemName: AppIcons.more)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.ink)
                .frame(width: 44, height: 44, alignment: .trailing)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("List options")
        .accessibilityHint("Rename, delete, or manage completed items")
    }

    private func listPickerLabel(lineLimit: Int) -> some View {
        Menu {
            ForEach(lists) { other in
                Button(other.name) {
                    onSelectList(other)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(EssentialText.attributed(listName))
                    .font(AppTypography.navTitle)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(lineLimit)
                    .multilineTextAlignment(usesStackedHeader ? .leading : .center)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                Image(systemName: "chevron.down")
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColors.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: usesStackedHeader ? .leading : .center)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Current list, \(listName)")
        .accessibilityHint("Opens list picker")
    }
}

private struct ListOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let showCompletedItems: Bool
    let canClearCompleted: Bool
    let onRename: () -> Void
    let onToggleCompletedVisibility: () -> Void
    let onClearCompleted: () -> Void
    let onDeleteList: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    optionRow(title: "Rename list", systemImage: "pencil", action: onRename)
                    optionRow(
                        title: showCompletedItems ? "Hide Completed Items" : "Show Completed Items",
                        systemImage: showCompletedItems ? "eye.slash" : "eye",
                        action: onToggleCompletedVisibility
                    )
                    if canClearCompleted {
                        optionRow(
                            title: "Clear Completed Items",
                            systemImage: "checkmark.circle",
                            action: onClearCompleted
                        )
                    }
                    Divider()
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.vertical, 4)
                    optionRow(
                        title: "Delete list",
                        systemImage: "trash",
                        isDestructive: true,
                        action: onDeleteList
                    )
                }
                .padding(.top, 8)
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle("List Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(listOptionsSheetHeight)])
        .presentationDragIndicator(.visible)
        .adaptiveSheetPresentation(.form)
    }

    private var listOptionsSheetHeight: CGFloat {
        var rows: CGFloat = 3
        if canClearCompleted { rows += 1 }
        return 56 + (rows * 52) + 24
    }

    private func optionRow(
        title: String,
        systemImage: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24)
                    .foregroundStyle(isDestructive ? AppColors.accentDestructive : AppColors.accentPrimary)
                Text(title)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(isDestructive ? AppColors.accentDestructive : AppColors.ink)
                Spacer(minLength: 0)
            }
            .adaptiveHorizontalPadding()
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

#if DEBUG
#Preview("Header · Large") {
    ListDetailHeaderPreview(dynamicTypeSize: .large, name: "B1 Produce Review")
}

#Preview("Header · Accessibility Large") {
    ListDetailHeaderPreview(dynamicTypeSize: .accessibility1, name: "B1 Produce Review")
}

#Preview("Header · Long name") {
    ListDetailHeaderPreview(dynamicTypeSize: .accessibility3, name: "A Very Long Grocery List Name")
}

private struct ListDetailHeaderPreview: View {
    let dynamicTypeSize: DynamicTypeSize
    let name: String

    var body: some View {
        ListDetailHeader(
            listName: name,
            lists: [GroceryList(name: name), GroceryList(name: "Weekly Groceries")],
            onBack: {},
            onSelectList: { _ in },
            onShareList: {},
            onRenameList: {},
            onToggleCompletedVisibility: {},
            onClearCompleted: {},
            onDeleteList: {}
        )
        .padding()
        .environment(\.dynamicTypeSize, dynamicTypeSize)
        .background(AppColors.backgroundGrouped)
    }
}
#endif
