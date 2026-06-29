import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Privacy Policy")
                            .font(AppTypography.onboardingTitle)
                            .foregroundStyle(AppColors.ink)
                        Text("Last updated: June 2026")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.inkSecondary)
                    }

                    policySection(
                        title: "Your data stays on your device",
                        body: "Grocery lists, items, stores, and preferences are stored locally on your iPhone. No account is required."
                    )

                    policySection(
                        title: "Sharing and import",
                        body: "Lists are only shared when you choose to share them. QR codes and shared text contain the list data you export. The other person receives their own copy."
                    )

                    policySection(
                        title: "Backup files",
                        body: "Backup files contain your saved lists and app data. You control where backup files are saved and who receives them."
                    )

                    policySection(
                        title: "Feedback",
                        body: "If you send feedback by email, your message and optional diagnostics (app version, iOS version, device model) are sent only when you choose to send. Grocery list contents are not included by default."
                    )

                    policySection(
                        title: "No selling of data",
                        body: "We do not sell your personal data. This app does not include advertising or third-party tracking in the current version."
                    )

                    if let url = AppConfig.privacyPolicyURL {
                        Button {
                            openURL(url)
                        } label: {
                            HStack(spacing: 8) {
                                Text("View full policy on the web")
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.semibold))
                            }
                            .font(AppTypography.button)
                            .foregroundStyle(AppColors.accentPrimary)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }

                    Text("Questions? Contact \(AppConfig.feedbackEmail)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.inkSecondary)
                        .padding(.top, 8)
                }
                .padding(AppSpacing.screenHorizontal)
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
            .background(AppColors.backgroundGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.itemTitle.weight(.semibold))
                .foregroundStyle(AppColors.ink)
            Text(body)
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    PrivacyPolicyView()
}
