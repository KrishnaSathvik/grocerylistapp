import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages = OnboardingTheme.pages

    var body: some View {
        OnboardingFullScreenPage(
            imageName: pages[page].imageName,
            title: pages[page].title,
            subtitle: pages[page].subtitle,
            pageIndex: page,
            pageCount: pages.count,
            showBack: page > 0,
            continueLabel: page == pages.count - 1 ? "Start my list" : "Next",
            onSkip: finish,
            onBack: { advance(by: -1) },
            onContinue: {
                if page == pages.count - 1 {
                    finish()
                } else {
                    advance(by: 1)
                }
            }
        )
        .id(page)
    }

    private func advance(by delta: Int) {
        HapticsService.navigation()
        let nextPage = page + delta
        guard pages.indices.contains(nextPage) else { return }

        if reduceMotion {
            page = nextPage
        } else {
            withAnimation(OnboardingTheme.pageSpring) {
                page = nextPage
            }
        }
    }

    private func finish() {
        HapticsService.navigation()
        AppSettings.hasCompletedOnboarding = true
        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
