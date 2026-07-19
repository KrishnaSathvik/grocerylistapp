import SwiftUI

struct ListStarterTemplateCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let template: ListStarterTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.colorHex(template.tintHex).opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: template.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.colorHex(template.tintHex))
                }

                Text(EssentialText.attributed(template.name))
                    .font(AppTypography.adaptiveCardTitle(for: dynamicTypeSize))
                    .foregroundStyle(AppColors.ink)
                    .essentialTextLayout(dynamicTypeSize: dynamicTypeSize, regularLineLimit: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AppColors.accentSuccess)
                    .frame(width: AppSpacing.minTapTarget, height: AppSpacing.minTapTarget)
            }
            .padding(14)
            .background(AppColors.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create \(template.name) list")
    }
}

#Preview {
    ListStarterTemplateCard(template: GroceryListService.starterTemplates[0], action: {})
        .padding()
}
