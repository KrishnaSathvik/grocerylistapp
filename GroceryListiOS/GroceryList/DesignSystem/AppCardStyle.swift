import SwiftUI
import SwiftData

struct AppCardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: AppColors.cardShadow, radius: 10, x: 0, y: 4)
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        modifier(AppCardStyle(padding: padding))
    }
}

// MARK: - Shared screen chrome

struct AppScreenBackground: View {
    var body: some View {
        ZStack(alignment: .top) {
            AppColors.backgroundGrouped

            LinearGradient(
                colors: [
                    AppColors.heroGradientTop,
                    AppColors.heroGradientTop.opacity(0.45),
                    AppColors.backgroundGrouped.opacity(0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
    }
}

/// Standard shell for My Lists, Store, Categories, and More.
struct TopLevelTabScreen<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            AppScreenBackground()

            VStack(spacing: 0) {
                TopLevelHeader(title: title, metadata: subtitle)

                content()
            }
            .frame(maxWidth: AppSpacing.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(AppScreenBackground())
        .tabBarSafePadding()
    }
}

typealias TopLevelHeader = TabScreenHeader
typealias PrimaryActionRow = TabPrimaryActionBar

struct GroupedItemsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppColors.cardShadow.opacity(0.35), radius: 8, y: 3)
    }
}

// MARK: - Grouped browse sections (Store / Categories tabs)

enum GroupedSectionKind {
    case store(storeId: String?, label: String)
    case category(categoryId: String, label: String)

    var metadataMode: GroupedItemMetadataMode {
        switch self {
        case .store: return .category
        case .category: return .store
        }
    }
}

/// Unified read-only group card for Store and Categories tabs.
struct GroupedSummaryCard: View {
    let kind: GroupedSectionKind
    let itemCount: Int
    let items: [GroceryItem]

    private let horizontalPadding: CGFloat = 14
    private let iconSize: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            groupHeader
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 12)

            if !items.isEmpty {
                Divider()
                    .overlay(AppColors.cardBorder)
                    .padding(.leading, horizontalPadding)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        GroupedItemRow(
                            item: item,
                            metadataMode: kind.metadataMode,
                            style: .nested
                        )

                        if index < items.count - 1 {
                            Divider()
                                .overlay(AppColors.cardBorder)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 6)
            }
        }
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupedSectionCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.groupedSectionCornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppColors.cardShadow.opacity(0.28), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var groupHeader: some View {
        HStack(spacing: 12) {
            groupIcon

            Text(groupTitle)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.ink)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(countLabel)
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.inkSecondary)
        }
    }

    @ViewBuilder
    private var groupIcon: some View {
        switch kind {
        case .store(let storeId, let label):
            StoreLogoView(
                storeId: storeId,
                displayLabel: label,
                size: iconSize,
                cornerRadius: 10
            )
        case .category(let categoryId, _):
            CategoryIconView(
                categoryId: categoryId,
                containerSize: iconSize,
                imageSize: 26,
                cornerRadius: 10
            )
        }
    }

    private var groupTitle: String {
        switch kind {
        case .store(_, let label): return label
        case .category(_, let label): return label
        }
    }

    private var countLabel: String {
        "\(itemCount) item\(itemCount == 1 ? "" : "s")"
    }
}

typealias GroupedSectionCard = GroupedSummaryCard
