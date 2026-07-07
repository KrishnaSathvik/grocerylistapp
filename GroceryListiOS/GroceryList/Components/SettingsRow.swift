import SwiftUI

struct SettingsRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var icon: String
    var iconColor: Color = AppColors.accentPrimary
    var showsChevron: Bool = true
    var isToggle: Bool = false
    @Binding var isOn: Bool

    init(
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        icon: String,
        iconColor: Color = AppColors.accentPrimary,
        showsChevron: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
        self.showsChevron = showsChevron
        self.isToggle = false
        self._isOn = .constant(false)
    }

    init(
        title: String,
        icon: String,
        iconColor: Color = AppColors.accentPrimary,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = nil
        self.value = nil
        self.icon = icon
        self.iconColor = iconColor
        self.showsChevron = false
        self.isToggle = true
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(colorScheme == .dark ? 0.24 : 0.14))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            if isToggle {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(AppColors.accentSuccess)
            } else {
                if let value {
                    Text(value)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                if showsChevron {
                    Image(systemName: AppIcons.chevron)
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.inkTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, subtitle == nil ? 14 : 16)
        .frame(maxWidth: .infinity, minHeight: AppSpacing.minTapTarget, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .appSectionLabel()
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                content
            }
            .background(AppColors.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.cardBorder)
            .frame(height: 1)
            .padding(.leading, 62)
    }
}
