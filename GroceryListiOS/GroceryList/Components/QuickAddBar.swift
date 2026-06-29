import SwiftUI

struct QuickAddBar: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding?
    var placeholder: String = "Add item…"
    var onSubmit: () -> Void

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.inkTertiary)
                .frame(width: 20)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .font(trimmed.isEmpty ? AppTypography.bodyMedium : AppTypography.itemTitle)
                .foregroundStyle(AppColors.ink)
                .submitLabel(.send)
                .onSubmit(submitIfValid)
                .modifier(QuickAddFocusModifier(focus: focus))

            if !trimmed.isEmpty {
                Button(action: submitIfValid) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColors.accentCTAForeground)
                        .frame(width: 28, height: 28)
                        .background(AppColors.accentCTA, in: Circle())
                }
                .buttonStyle(.plain)
                .frame(width: AppSpacing.minTapTarget, height: AppSpacing.minTapTarget)
                .contentShape(Rectangle())
                .accessibilityLabel("Add item")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: AppSpacing.addBarHeight)
        .background(AppColors.addBarBackground, in: Capsule())
        .overlay(
            Capsule()
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppColors.cardShadow.opacity(0.45), radius: 6, y: 2)
        .animation(.easeInOut(duration: 0.18), value: trimmed.isEmpty)
    }

    private func submitIfValid() {
        guard !trimmed.isEmpty else { return }
        onSubmit()
    }
}

private struct QuickAddFocusModifier: ViewModifier {
    var focus: FocusState<Bool>.Binding?

    func body(content: Content) -> some View {
        if let focus {
            content.focused(focus)
        } else {
            content
        }
    }
}
