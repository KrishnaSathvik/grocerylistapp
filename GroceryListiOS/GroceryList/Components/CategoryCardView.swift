import SwiftUI

struct CategoryCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let categoryId: String
    let label: String
    let itemCount: Int
    var isExpanded: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            CategoryIconView(
                categoryId: categoryId,
                containerSize: 44,
                cornerRadius: 12
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(EssentialText.attributed(label))
                    .font(AppTypography.adaptiveCardTitle(for: dynamicTypeSize))
                    .foregroundStyle(AppColors.ink)
                    .essentialTextLayout(dynamicTypeSize: dynamicTypeSize, regularLineLimit: 1)
                Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: isExpanded ? "chevron.up" : AppIcons.chevron)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.inkSecondary)
                .frame(width: AppSpacing.minTapTarget, height: AppSpacing.minTapTarget, alignment: .topTrailing)
        }
        .appCard()
    }
}

#Preview {
    CategoryCardView(categoryId: "produce", label: "Produce", itemCount: 3)
        .padding()
        .background(AppColors.backgroundGrouped)
}

struct CategorySectionHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let categoryId: String
    let label: String
    let itemCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CategoryIconView(
                categoryId: categoryId,
                containerSize: 36,
                cornerRadius: 10
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(EssentialText.attributed(label))
                    .font(AppTypography.adaptiveCardTitle(for: dynamicTypeSize))
                    .foregroundStyle(AppColors.ink)
                    .essentialTextLayout(dynamicTypeSize: dynamicTypeSize, regularLineLimit: 1)
                Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppColors.cardShadow.opacity(0.35), radius: 8, y: 3)
    }
}
