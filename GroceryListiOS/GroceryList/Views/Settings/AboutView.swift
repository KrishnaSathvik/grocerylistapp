import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showWebsite = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        appIcon
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: AppColors.accentPrimary.opacity(0.2), radius: 12, y: 4)
                            .accessibilityHidden(true)

                        VStack(spacing: 6) {
                            Text("Groceries — Smart Lists")
                                .font(AppTypography.onboardingTitle)
                                .foregroundStyle(AppColors.ink)

                            Text("Smart grocery lists for iOS")
                                .font(AppTypography.metadata)
                                .foregroundStyle(AppColors.inkSecondary)

                            Text("Version \(AppSupport.appVersion)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.inkSecondary)
                        }
                    }
                    .padding(.top, 8)

                    VStack(spacing: 0) {
                        featureRow("Local-first")
                        SettingsDivider()
                        featureRow("No account required")
                        SettingsDivider()
                        featureRow("Smart natural input")
                        SettingsDivider()
                        featureRow("Share and import lists")
                    }
                    .background(AppColors.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )

                    if AppConfig.marketingPageURL != nil {
                        Button {
                            showWebsite = true
                        } label: {
                            HStack(spacing: 8) {
                                Text("Visit our website")
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.semibold))
                            }
                            .font(AppTypography.button)
                            .foregroundStyle(AppColors.accentPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .adaptiveScreenContent()
                .padding(.bottom, 32)
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showWebsite) {
                if let url = AppConfig.marketingPageURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private var appIcon: some View {
        let previewName = AppIconService.currentOption.previewAssetName
        if UIImage(named: previewName) != nil {
            Image(previewName)
                .resizable()
                .scaledToFit()
        } else if UIImage(named: "app-brand-icon") != nil {
            Image("app-brand-icon")
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "basket.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.accentSuccess)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.accentSuccess.opacity(0.14))
        }
    }

    private func featureRow(_ title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.accentSuccess)
            Text(title)
                .font(AppTypography.itemTitle)
                .foregroundStyle(AppColors.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    AboutView()
}
