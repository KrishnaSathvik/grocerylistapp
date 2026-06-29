import SwiftUI
import UIKit

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var feedbackType: FeedbackType = .support
    @State private var message = ""
    @State private var includeDiagnostics = true
    @State private var showMailComposer = false
    @State private var showFallbackSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Send feedback or get support by email.")
                            .font(AppTypography.metadata)
                            .foregroundStyle(AppColors.inkSecondary)
                        Text(AppConfig.feedbackEmail)
                            .font(AppTypography.itemTitle)
                            .foregroundStyle(AppColors.ink)
                            .textSelection(.enabled)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("What would you like to share?")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)

                        Picker("Feedback type", selection: $feedbackType) {
                            ForEach(FeedbackType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Feedback type")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)

                        TextField(
                            "Tell us what happened or what you'd like to see.",
                            text: $message,
                            axis: .vertical
                        )
                        .lineLimit(5...10)
                        .font(AppTypography.itemTitle)
                        .padding(14)
                        .background(AppColors.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                        .accessibilityLabel("Feedback message")
                    }

                    Toggle(isOn: $includeDiagnostics) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Include app diagnostics")
                                .font(AppTypography.itemTitle)
                                .foregroundStyle(AppColors.ink)
                            Text("Version, iOS version, device model")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.inkSecondary)
                        }
                    }
                    .tint(AppColors.accentPrimary)
                    .accessibilityHint("Includes app version and device details in your email")

                    Text("This opens your email app so you can review before sending.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.inkSecondary)
                        .accessibilityLabel("This opens your email app so you can review before sending")

                    Button("Send Email") {
                        sendFeedback()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Send feedback email")
                }
                .adaptiveScreenContent()
                .padding(.vertical, 16)
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle("Feedback & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(
                    subject: feedbackType.emailSubject,
                    body: emailBody,
                    recipients: [AppConfig.feedbackEmail]
                )
            }
            .sheet(isPresented: $showFallbackSheet) {
                FeedbackFallbackSheet(
                    subject: feedbackType.emailSubject,
                    feedbackBody: emailBody,
                    onDismiss: { showFallbackSheet = false }
                )
            }
        }
        .presentationDetents([.large])
    }

    private var emailBody: String {
        var lines = [
            "Hi,",
            "",
            "Feedback type: \(feedbackType.rawValue)",
            "",
            message.trimmingCharacters(in: .whitespacesAndNewlines),
            "",
        ]
        if includeDiagnostics {
            lines.append("App details:")
            lines.append(AppSupport.diagnostics(includeAppearance: false))
        }
        return lines.joined(separator: "\n")
    }

    private func sendFeedback() {
        if MailComposeView.canSendMail {
            showMailComposer = true
            return
        }

        let subject = feedbackType.emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(AppConfig.feedbackEmail)?subject=\(subject)&body=\(body)") {
            openURL(url) { accepted in
                if !accepted {
                    showFallbackSheet = true
                }
            }
            return
        }

        showFallbackSheet = true
    }
}

private struct FeedbackFallbackSheet: View {
    let subject: String
    let feedbackBody: String
    let onDismiss: () -> Void

    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Mail isn't set up on this device. Copy your feedback below or copy our support email.")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                ScrollView {
                    Text(feedbackBody)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(AppColors.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(spacing: 10) {
                    Button("Copy Feedback") {
                        UIPasteboard.general.string = feedbackBody
                        toastMessage = "Feedback copied"
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Copy Support Email") {
                        UIPasteboard.general.string = AppConfig.feedbackEmail
                        toastMessage = "Email copied"
                    }
                    .font(AppTypography.button)
                    .foregroundStyle(AppColors.accentPrimary)
                }
                .padding(.bottom, 24)
            }
            .adaptiveScreenContent()
            .background(AppColors.backgroundGrouped)
            .navigationTitle(subject)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
            .overlay(alignment: .bottom) {
                if let toastMessage {
                    Text(toastMessage)
                        .font(AppTypography.metadata.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppColors.ink.opacity(0.92))
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    FeedbackView()
}
