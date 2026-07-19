import SwiftUI

enum QuickAddCopy {
    static let helper = "Try “2 eggs from Walmart”"
}

struct QuickAddHelperText: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Text(QuickAddCopy.helper)
            .font(AppTypography.metadata)
            .foregroundStyle(AppColors.inkSecondary)
            .lineLimit(DynamicTypeLayout.usesAccessibilityLayout(dynamicTypeSize) ? nil : 2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(QuickAddCopy.helper)
    }
}
