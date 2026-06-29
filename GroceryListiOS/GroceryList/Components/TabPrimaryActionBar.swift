import SwiftUI

struct TabPrimaryActionBar: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColors.accentPrimary)
                Text(title)
                    .font(AppTypography.button)
                    .foregroundStyle(AppColors.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: AppSpacing.minTapTarget)
            .background(AppColors.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: AppColors.cardShadow.opacity(0.45), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}
