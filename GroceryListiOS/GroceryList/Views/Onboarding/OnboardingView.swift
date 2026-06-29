import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages = OnboardingTheme.pages

    var body: some View {
        TabView(selection: $page) {
            ForEach(pages.indices, id: \.self) { index in
                OnboardingFullScreenPage(
                    imageName: pages[index].imageName,
                    title: pages[index].title,
                    subtitle: pages[index].subtitle,
                    isActive: page == index,
                    pageIndex: index,
                    pageCount: pages.count,
                    showBack: index > 0,
                    continueLabel: index == pages.count - 1 ? "Start my list" : "Next",
                    onSkip: finish,
                    onBack: { advance(by: -1) },
                    onContinue: {
                        if index == pages.count - 1 {
                            finish()
                        } else {
                            advance(by: 1)
                        }
                    }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(reduceMotion ? nil : OnboardingTheme.pageSpring, value: page)
        .ignoresSafeArea()
    }

    private func advance(by delta: Int) {
        HapticsService.navigation()
        if reduceMotion {
            page += delta
        } else {
            withAnimation(OnboardingTheme.pageSpring) {
                page += delta
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
