import SwiftUI

struct OnboardingFullScreenPage: View {
    let imageName: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let pageIndex: Int
    let pageCount: Int
    let showBack: Bool
    let continueLabel: String
    let onSkip: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentVisible = false

    private var isFinalPage: Bool {
        pageIndex == pageCount - 1
    }

    var body: some View {
        ZStack {
            backgroundImage
            scrimOverlay

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, 12)

                Spacer(minLength: 0)

                bottomPanel
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: isActive) { _, active in
            if active {
                revealContent()
            } else {
                contentVisible = false
            }
        }
        .onAppear {
            if isActive { revealContent() }
        }
    }

    // MARK: - Background

    private var backgroundImage: some View {
        GeometryReader { proxy in
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .scaleEffect(contentVisible ? 1 : 1.04)
                .animation(reduceMotion ? nil : OnboardingTheme.heroSpring, value: contentVisible)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var scrimOverlay: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.28),
                Color.white.opacity(0.05),
                Color.black.opacity(0.06),
                Color.black.opacity(0.30),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Top

    private var topBar: some View {
        ZStack(alignment: .top) {
            Text("Grocery List")
                .font(OnboardingTheme.brandHeadline)
                .foregroundStyle(AppColors.ink)
                .shadow(color: .white.opacity(0.65), radius: 8, y: 2)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Spacer()
                Button("Skip", action: onSkip)
                    .font(AppTypography.metadata.weight(.semibold))
                    .foregroundStyle(AppColors.inkSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .accessibilityLabel("Skip onboarding")
            }
        }
    }

    // MARK: - Bottom

    private var bottomPanel: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text(title)
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(subtitle)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)

            bottomControls
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .safeAreaPadding(.bottom)
        .frame(maxWidth: .infinity)
        .background(bottomPanelBackground)
        .opacity(contentVisible ? 1 : 0)
        .offset(y: contentVisible ? 0 : 20)
        .animation(reduceMotion ? nil : OnboardingTheme.heroSpring, value: contentVisible)
    }

    private var bottomControls: some View {
        HStack(alignment: .center, spacing: 12) {
            backControl
                .frame(width: 52, height: 52)

            OnboardingPageDots(count: pageCount, current: pageIndex)
                .frame(maxWidth: .infinity)

            primaryActionButton
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityValue("Page \(pageIndex + 1) of \(pageCount)")
    }

    @ViewBuilder
    private var backControl: some View {
        if showBack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppColors.ink)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.cardBorder.opacity(0.5), lineWidth: 0.5)
                    )
            }
            .accessibilityLabel("Previous onboarding page")
        } else {
            Color.clear
                .frame(width: 52, height: 52)
                .accessibilityHidden(true)
        }
    }

    private var primaryActionButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 6) {
                Text(continueLabel)
                    .lineLimit(1)
                Image(systemName: "arrow.right")
                    .font(.footnote.weight(.bold))
            }
            .font(AppTypography.button)
            .foregroundStyle(.white)
            .padding(.horizontal, isFinalPage ? 16 : 20)
            .frame(height: 52)
            .background(AppColors.accentPrimary, in: Capsule())
            .shadow(color: AppColors.accentPrimary.opacity(0.28), radius: 10, y: 4)
        }
        .accessibilityLabel(isFinalPage ? "Start my list" : "Next onboarding page")
    }

    private var bottomPanelBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.55),
                    Color.white.opacity(0.90),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .mask {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 28)
                Rectangle()
            }
        }
    }

    private func revealContent() {
        if reduceMotion {
            contentVisible = true
            return
        }
        withAnimation(OnboardingTheme.heroSpring) {
            contentVisible = true
        }
    }
}

#Preview {
    OnboardingFullScreenPage(
        imageName: "onboarding_shop_smarter",
        title: "Shop smarter",
        subtitle: "Type groceries in any order. We sort them into the right categories automatically.",
        isActive: true,
        pageIndex: 0,
        pageCount: 4,
        showBack: false,
        continueLabel: "Next",
        onSkip: {},
        onBack: {},
        onContinue: {}
    )
}
