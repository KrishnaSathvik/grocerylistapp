import SwiftUI

struct CategoryCardView: View {
    let categoryId: String
    let label: String
    let itemCount: Int
    var isExpanded: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            CategoryIconView(
                categoryId: categoryId,
                containerSize: 44,
                cornerRadius: 12
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(1)
                Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: isExpanded ? "chevron.up" : AppIcons.chevron)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.inkSecondary)
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
    let categoryId: String
    let label: String
    let itemCount: Int

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(
                categoryId: categoryId,
                containerSize: 36,
                cornerRadius: 10
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(1)
                Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
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
