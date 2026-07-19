import SwiftUI
import SwiftData

// MARK: - Shared tab chrome

struct TabHeaderActionButton: View {
    let systemName: String
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AppColors.accentCTA)
                .clipShape(Circle())
                .shadow(color: AppColors.accentCTA.opacity(0.25), radius: 8, y: 3)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

struct TabScreenHeader<Action: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    var metadata: String?
    @ViewBuilder let action: () -> Action

    private var usesCompactTitle: Bool {
        DynamicTypeLayout.usesCompactScreenTitle(dynamicTypeSize)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: usesCompactTitle ? 4 : 6) {
                Text(EssentialText.attributed(title))
                    .font(AppTypography.topLevelScreenTitle(for: dynamicTypeSize))
                    .foregroundStyle(AppColors.ink)
                    .essentialTextLayout(dynamicTypeSize: dynamicTypeSize, regularLineLimit: 2)
                    .multilineTextAlignment(.leading)

                if let metadata {
                    Text(metadata)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(usesCompactTitle ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            action()
        }
        .adaptiveHorizontalPadding()
        .safeAreaPadding(.top, AppSpacing.topHeaderTopInset)
        .padding(.bottom, usesCompactTitle ? 8 : AppSpacing.topHeaderBottomSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension TabScreenHeader where Action == EmptyView {
    init(title: String, metadata: String? = nil) {
        self.title = title
        self.metadata = metadata
        self.action = { EmptyView() }
    }
}

#Preview("Lists Header") {
    TopLevelHeader(
        title: "My Lists",
        metadata: "Plan each grocery run and keep everything organized."
    )
    .background(AppScreenBackground())
}

#Preview("Store Header") {
    TopLevelHeader(
        title: "Store",
        metadata: "See what to buy from each store."
    ) {
        TabHeaderActionButton(systemName: AppIcons.add, accessibilityLabel: "Add item", action: {})
    }
    .background(AppScreenBackground())
}
