import SwiftUI
import UIKit

/// Renders emoji reliably. Do not draw emoji into a bitmap with `UIFont.systemFont` —
/// SF Pro has no emoji glyphs and produces `[?]` on simulator and device alike.
struct EmojiLabel: View {
    let emoji: String
    var size: CGFloat = 28

    var body: some View {
        EmojiLabelRepresentable(emoji: emoji, size: size)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

private struct EmojiLabelRepresentable: UIViewRepresentable {
    let emoji: String
    let size: CGFloat

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.text = emoji
        label.font = .systemFont(ofSize: size)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        EmojiLabel(emoji: "🥛", size: 32)
        EmojiLabel(emoji: "🍌", size: 32)
        EmojiLabel(emoji: "🍗", size: 32)
        EmojiLabel(emoji: "🥚", size: 32)
    }
    .padding()
}
#endif
