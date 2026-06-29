import SwiftUI

struct UndoBanner: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(AppTypography.metadata)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button("Undo", action: onUndo)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .accessibilityLabel("Undo")
                .accessibilityHint("Restores the deleted item")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.ink)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .adaptiveHorizontalPadding()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    UndoBanner(message: "Deleted \"Milk\"", onUndo: {})
        .padding(.bottom)
        .background(AppColors.backgroundGrouped)
}

struct ToastBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(AppTypography.metadata)
            .foregroundStyle(.white)
            .lineLimit(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.ink)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            .adaptiveHorizontalPadding()
            .accessibilityLabel(message)
    }
}
