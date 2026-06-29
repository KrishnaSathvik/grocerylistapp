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
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppColors.accentPrimary)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .font(trimmed.isEmpty ? AppTypography.bodyMedium : AppTypography.itemTitle)
                .foregroundStyle(AppColors.ink)
                .submitLabel(.done)
                .onSubmit(submitIfValid)
                .modifier(QuickAddFocusModifier(focus: focus))

            if !trimmed.isEmpty {
                Button(action: submitIfValid) {
                    Image(systemName: AppIcons.add)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(AppColors.accentPrimary, in: Circle())
                }
                .buttonStyle(.plain)
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
