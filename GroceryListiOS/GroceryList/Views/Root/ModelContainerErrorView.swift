import SwiftUI

struct ModelContainerErrorView: View {
    let error: Error
    let onReset: () -> Void

    @State private var isResetting = false
    @State private var resetFailed = false

    var body: some View {
        ZStack {
            AppColors.backgroundGrouped.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.accentDestructive)

                VStack(spacing: 8) {
                    Text("Couldn't Load Your Lists")
                        .font(AppTypography.onboardingTitle)
                        .foregroundStyle(AppColors.ink)
                        .multilineTextAlignment(.center)

                    Text("Grocery List couldn't open its local database. Your data may be corrupted. You can reset local storage and start fresh.")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                if resetFailed {
                    Text("Reset failed. Please delete and reinstall the app.")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.accentDestructive)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button {
                        isResetting = true
                        resetFailed = false
                        onReset()
                    } label: {
                        if isResetting {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                        } else {
                            Text("Reset Local Data")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isResetting)

                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(AppColors.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }
            .adaptiveScreenContent(alignment: .center)
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ModelContainerErrorView(error: NSError(domain: "test", code: 1)) {}
}
