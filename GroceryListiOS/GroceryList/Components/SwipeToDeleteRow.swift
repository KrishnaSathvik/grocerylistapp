import SwiftUI

/// Card-aligned swipe-to-delete with a full-height red action (replaces floating List swipe buttons).
struct SwipeToDeleteRow<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var cornerRadius: CGFloat = 14
    var isEnabled: Bool = true
    let onDelete: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var settledOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let actionWidth: CGFloat = 80
    private let openThreshold: CGFloat = 36
    private let deleteThreshold: CGFloat = 132

    private var totalOffset: CGFloat {
        guard isEnabled else { return 0 }
        return max(-actionWidth * 1.35, min(0, settledOffset + dragOffset))
    }

    private var revealedWidth: CGFloat {
        max(actionWidth, -totalOffset)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteBackground

            content()
                .offset(x: totalOffset)
                .gesture(swipeGesture)
        }
        .accessibilityAction(named: "Delete", performDelete)
        .onChange(of: isEnabled) { _, enabled in
            if !enabled { settle(to: 0) }
        }
    }

    private var deleteBackground: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            Button(action: performDelete) {
                ZStack {
                    AppColors.accentDestructive

                    if revealedWidth >= 52 {
                        VStack(spacing: 5) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Delete")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.leading, 4)
                    }
                }
                .frame(width: revealedWidth)
                .frame(maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete")
        }
        .background(AppColors.accentDestructive)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .local)
            .updating($dragOffset) { value, state, _ in
                guard isEnabled else { return }
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) else { return }
                guard horizontal < 0 else { return }
                state = horizontal
            }
            .onEnded { value in
                guard isEnabled else { return }
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) else {
                    settle(to: settledOffset)
                    return
                }

                let projected = settledOffset + horizontal
                if projected <= -deleteThreshold {
                    commitDelete()
                } else if projected <= -openThreshold {
                    settle(to: -actionWidth)
                } else {
                    settle(to: 0)
                }
            }
    }

    private func settle(to offset: CGFloat) {
        if reduceMotion {
            settledOffset = offset
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                settledOffset = offset
            }
        }
    }

    private func performDelete() {
        guard isEnabled else { return }
        commitDelete()
    }

    private func commitDelete() {
        if reduceMotion {
            settledOffset = 0
            onDelete()
        } else {
            withAnimation(.easeOut(duration: 0.18)) {
                settledOffset = -revealedWidth * 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                settledOffset = 0
                onDelete()
            }
        }
    }
}
