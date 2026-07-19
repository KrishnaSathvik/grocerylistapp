import SwiftUI

struct SettingsRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

    private var usesStackedAccessories: Bool {
        DynamicTypeLayout.usesStackedSettingsAccessories(dynamicTypeSize)
    }

    var body: some View {
        Group {
            if usesStackedAccessories {
                stackedBody
            } else {
                compactBody
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, subtitle == nil ? 14 : 16)
        .frame(maxWidth: .infinity, minHeight: AppSpacing.minTapTarget, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var compactBody: some View {
        HStack(spacing: 14) {
            iconBadge
            titleBlock.frame(maxWidth: .infinity, alignment: .leading)
            accessories
        }
    }

    private var stackedBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                iconBadge
                titleBlock.frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                accessories
            }
        }
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(iconColor.opacity(colorScheme == .dark ? 0.24 : 0.14))
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(iconColor)
        }
        .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(EssentialText.attributed(title))
                .font(AppTypography.itemTitle)
                .foregroundStyle(AppColors.ink)
                .essentialTextLayout(dynamicTypeSize: dynamicTypeSize, regularLineLimit: 2)
                .multilineTextAlignment(.leading)
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.inkSecondary)
                    .lineLimit(DynamicTypeLayout.usesAccessibilityLayout(dynamicTypeSize) ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    @ViewBuilder
    private var accessories: some View {
        if isToggle {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.accentSuccess)
        } else {
            if let value {
                Text(value)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .lineLimit(DynamicTypeLayout.usesAccessibilityLayout(dynamicTypeSize) ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if showsChevron {
                Image(systemName: AppIcons.chevron)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.inkTertiary)
            }
        }
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
            VStack(spacing: 0) { content }
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Rectangle()
            .fill(AppColors.cardBorder)
            .frame(height: 1)
            .padding(
                .leading,
                DynamicTypeLayout.usesAccessibilityLayout(dynamicTypeSize) ? 16 : 62
            )
    }
}

#if DEBUG
#Preview("Settings · Large") {
    SettingsRowPreviewHost(dynamicTypeSize: .large)
}

#Preview("Settings · Accessibility Large") {
    SettingsRowPreviewHost(dynamicTypeSize: .accessibility1)
}

private struct SettingsRowPreviewHost: View {
    let dynamicTypeSize: DynamicTypeSize
    @State private var haptics = true

    var body: some View {
        ScrollView {
            SettingsCard(title: "Preferences") {
                SettingsRow(title: "Haptic Feedback", icon: "hand.tap", iconColor: AppColors.accentSuccess, isOn: $haptics)
                SettingsDivider()
                SettingsRow(title: "Appearance", value: "System", icon: "circle.lefthalf.filled", iconColor: AppColors.colorHex("#8B6F8E"))
                SettingsDivider()
                SettingsRow(
                    title: "Import a Shared List",
                    subtitle: "Scan a QR code or paste copied list text.",
                    icon: "square.and.arrow.down",
                    iconColor: AppColors.accentSuccess
                )
            }
            .padding()
        }
        .environment(\.dynamicTypeSize, dynamicTypeSize)
        .background(AppColors.backgroundGrouped)
    }
}
#endif
