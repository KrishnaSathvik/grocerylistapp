import SwiftUI

struct AppIconPickerView: View {
    @State private var selectedOption = AppIconService.currentOption
    @State private var isApplying = false
    @State private var statusMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Choose how Groceries — Smart Lists looks on your Home Screen.")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .padding(.horizontal, 4)

                if !AppIconService.supportsAlternateIcons {
                    Text("Icon changes apply on a physical iPhone. You can still preview all six options here.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.inkSecondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 4)
                }

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AppIconOption.all) { option in
                        iconCard(option)
                    }
                }
            }
            .adaptiveScreenContent()
            .padding(.vertical, 16)
            .padding(.bottom, 8)
        }
        .background(AppColors.backgroundGrouped)
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .settingsSubpageStyle()
        .alert("App Icon", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private func iconCard(_ option: AppIconOption) -> some View {
        let isSelected = selectedOption == option

        return Button {
            apply(option)
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(option.previewAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isSelected ? AppColors.accentPrimary : AppColors.cardBorder, lineWidth: isSelected ? 2.5 : 1)
                        )
                        .shadow(color: AppColors.ink.opacity(0.08), radius: 8, y: 3)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.accentPrimary)
                            .background(Circle().fill(AppColors.backgroundPrimary))
                            .offset(x: 6, y: -6)
                    }
                }

                Text(option.label)
                    .font(AppTypography.metadata.weight(.semibold))
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(AppColors.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isApplying)
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Applies this home screen icon")
    }

    private func apply(_ option: AppIconOption) {
        guard !isApplying else { return }
        isApplying = true

        Task { @MainActor in
            defer { isApplying = false }
            do {
                try await AppIconService.setIcon(option)
                selectedOption = option
                if AppSettings.enableHaptics {
                    HapticsService.selection()
                }
            } catch {
                statusMessage = "Couldn't change the app icon. Try again."
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppIconPickerView()
    }
}
