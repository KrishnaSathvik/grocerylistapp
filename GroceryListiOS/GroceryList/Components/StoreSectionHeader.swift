import SwiftUI

struct StoreSectionHeader: View {
    let storeId: String?
    let label: String
    let itemCount: Int

    var body: some View {
        HStack(spacing: 12) {
            StoreLogoView(storeId: storeId, displayLabel: label, size: 44, cornerRadius: 11)

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

#Preview {
    StoreSectionHeader(storeId: "costco", label: "Costco", itemCount: 4)
        .padding()
}
