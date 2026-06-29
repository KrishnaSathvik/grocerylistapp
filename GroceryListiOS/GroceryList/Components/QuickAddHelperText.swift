import SwiftUI

enum QuickAddCopy {
    static let helper = "Try “2 eggs from Walmart”"
}

struct QuickAddHelperText: View {
    var body: some View {
        Text(QuickAddCopy.helper)
            .font(AppTypography.metadata)
            .foregroundStyle(AppColors.inkSecondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(QuickAddCopy.helper)
    }
}
