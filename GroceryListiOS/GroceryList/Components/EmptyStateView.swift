import SwiftUI

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String = "bag"
    var primaryTitle: String?
    var primaryAction: (() -> Void)?
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?
    var starterChips: [String] = []
    var onStarterChip: ((String) -> Void)?

    var body: some View {
        EmptyStateScene(
            title: title,
            message: message,
            illustration: {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.heroGradientTop, AppColors.backgroundPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    Image(systemName: systemImage)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(AppColors.accentSuccess)
                        .symbolRenderingMode(.hierarchical)
                }
                .shadow(color: AppColors.cardShadow, radius: 10, y: 4)
            },
            primaryTitle: primaryTitle,
            primaryAction: primaryAction,
            secondaryTitle: secondaryTitle,
            secondaryAction: secondaryAction,
            starterChips: starterChips,
            onStarterChip: onStarterChip
        )
    }
}

#Preview {
    EmptyStateView(
        title: "Your list is empty",
        message: "Add your first item or import a saved list to get started.",
        systemImage: "bag",
        primaryTitle: "Add Item",
        primaryAction: {},
        secondaryTitle: "Import List",
        secondaryAction: {},
        starterChips: ["2 eggs from Walmart", "bananas 6", "bread from Trader Joe's"],
        onStarterChip: { _ in }
    )
    .background(AppColors.backgroundGrouped)
}
