import SwiftUI

struct ListStarterTemplateCard: View {
    let template: ListStarterTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.colorHex(template.tintHex).opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: template.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.colorHex(template.tintHex))
                }

                Text(template.name)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AppColors.accentSuccess)
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
