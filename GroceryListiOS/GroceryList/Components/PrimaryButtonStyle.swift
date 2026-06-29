import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.largeButton)
            .foregroundStyle(AppColors.accentCTAForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.accentCTA)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous))
            .shadow(
                color: AppColors.accentCTA.opacity(configuration.isPressed ? 0.1 : 0.28),
                radius: 10,
                y: 4
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.92 : 1) : 0.45)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1)
    }
}
