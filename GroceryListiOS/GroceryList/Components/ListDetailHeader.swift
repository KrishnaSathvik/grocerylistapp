import SwiftUI

struct ListDetailHeader: View {
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

    @State private var showListOptions = false

    var body: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.ink)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to lists")

                Spacer(minLength: 0)

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
                .accessibilityHint("Share, rename, or manage completed items")
            }

            Menu {
                ForEach(lists) { other in
                    Button(other.name) {
                        onSelectList(other)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(listName)
                        .font(AppTypography.navTitle)
                        .foregroundStyle(AppColors.ink)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColors.inkSecondary)
                }
            }
            .accessibilityLabel("Current list, \(listName)")
            .accessibilityHint("Opens list picker")
        }
        .frame(height: 44)
        .sheet(isPresented: $showListOptions) {
            ListOptionsSheet(
                showCompletedItems: showCompletedItems,
                canClearCompleted: canClearCompleted,
                onShare: {
                    showListOptions = false
                    onShareList()
                },
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
                }
            )
        }
    }
}

private struct ListOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let showCompletedItems: Bool
    let canClearCompleted: Bool
    let onShare: () -> Void
    let onRename: () -> Void
    let onToggleCompletedVisibility: () -> Void
    let onClearCompleted: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                optionRow(
                    title: "Share list",
                    systemImage: AppIcons.share,
                    action: onShare
                )
                optionRow(
                    title: "Rename list",
                    systemImage: "pencil",
                    action: onRename
                )
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
                Spacer(minLength: 0)
            }
            .padding(.top, 8)
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func optionRow(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24)
                    .foregroundStyle(AppColors.accentPrimary)

                Text(title)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
