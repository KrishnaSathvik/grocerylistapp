import SwiftUI

struct ImportExportActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.ink)
                    Text(subtitle)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                }

                Spacer(minLength: 0)

                    Image(systemName: AppIcons.chevron)
                        .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.inkSecondary.opacity(0.6))
            }
            .appCard(padding: 14)
        }
        .buttonStyle(.plain)
    }
}

struct ImportExportInfoCallout: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.accentSuccess)
            Text(text)
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.heroGradientTop.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.accentSuccess.opacity(0.18), lineWidth: 1)
        )
    }
}
