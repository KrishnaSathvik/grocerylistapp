import SwiftUI

struct SelectionToolbar: View {
    let selectedCount: Int
    var onAssign: () -> Void
    var onShare: () -> Void
    var onCopy: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            toolbarButton(title: "Assign", icon: "folder", action: onAssign)
            toolbarButton(title: "Share", icon: AppIcons.share, action: onShare)
            toolbarButton(title: "Copy", icon: AppIcons.clipboard, action: onCopy)
            toolbarButton(title: "Delete", icon: "trash", action: onDelete, isDestructive: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppColors.cardShadow, radius: 12, y: 4)
        .adaptiveHorizontalPadding()
        .accessibilityLabel("\(selectedCount) selected")
    }

    private func toolbarButton(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        isDestructive: Bool = false
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isDestructive ? AppColors.accentDestructive : AppColors.accentPrimary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .frame(minHeight: 44)
    }
}
