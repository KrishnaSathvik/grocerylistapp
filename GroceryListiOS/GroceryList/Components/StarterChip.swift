import SwiftUI

struct StarterChip: View {
    let title: String
    let action: () -> Void

    private var chipEmoji: String? {
        let parsed = ItemInputParser.parse(title)
        return ItemEmojiCatalog.emoji(for: parsed.normalizedName)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let chipEmoji {
                    EmojiLabel(emoji: chipEmoji, size: 18)
                }
                Text(title)
                    .font(AppTypography.button)
                    .foregroundStyle(AppColors.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColors.backgroundPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: AppColors.cardShadow.opacity(0.6), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Try adding \(title)")
    }
}

#Preview {
    HStack {
        StarterChip(title: "2 eggs from Walmart", action: {})
        StarterChip(title: "bananas", action: {})
    }
    .padding()
}
