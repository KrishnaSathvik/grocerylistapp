import SwiftUI

struct StoreSectionHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let storeId: String?
    let label: String
    let itemCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StoreLogoView(storeId: storeId, displayLabel: label, size: 44, cornerRadius: 11)

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

#Preview {
    StoreSectionHeader(storeId: "costco", label: "Costco", itemCount: 4)
        .padding()
}
