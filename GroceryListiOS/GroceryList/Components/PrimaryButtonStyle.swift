import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.largeButton)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.accentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous))
            .shadow(color: AppColors.accentPrimary.opacity(configuration.isPressed ? 0.1 : 0.28), radius: 10, y: 4)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
