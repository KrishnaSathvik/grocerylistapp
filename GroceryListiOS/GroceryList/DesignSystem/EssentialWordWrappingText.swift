import SwiftUI
import UIKit

/// Word-wrapping essential title via UIKit `UILabel` so Dynamic Type text does not mid-word hyphenate.
/// Matches `AppTypography.itemTitle` (body / semibold) with content-size scaling.
struct EssentialWordWrappingText: View {
    let text: String
    var color: Color = AppColors.ink
    var isStrikethrough: Bool = false

    var body: some View {
        EssentialWordWrappingLabelRepresentable(
            text: text,
            color: color,
            isStrikethrough: isStrikethrough
        )
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
        .accessibilityHidden(true)
    }
}

private struct EssentialWordWrappingLabelRepresentable: UIViewRepresentable {
    let text: String
    let color: Color
    let isStrikethrough: Bool

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        configure(label)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        configure(label)
        let font = AppTypography.itemTitleUIFont(compatibleWith: label.traitCollection)
        label.attributedText = EssentialText.nsAttributed(
            text,
            font: font,
            color: UIColor(color),
            strikethrough: isStrikethrough
        )
    }

    private func configure(_ label: UILabel) {
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        // Disable standard line-break strategy; it can hyphenate despite hyphenationFactor 0.
        label.lineBreakStrategy = []
        label.adjustsFontForContentSizeCategory = true
        label.backgroundColor = .clear
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UILabel,
        context: Context
    ) -> CGSize? {
        let font = AppTypography.itemTitleUIFont(compatibleWith: uiView.traitCollection)
        uiView.attributedText = EssentialText.nsAttributed(
            text,
            font: font,
            color: UIColor(color),
            strikethrough: isStrikethrough
        )

        if let width = proposal.width, width.isFinite, width > 0 {
            uiView.preferredMaxLayoutWidth = width
            let fitted = uiView.sizeThatFits(
                CGSize(width: width, height: .greatestFiniteMagnitude)
            )
            return CGSize(width: width, height: ceil(fitted.height))
        }

        uiView.preferredMaxLayoutWidth = 0
        let fitted = uiView.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: ceil(fitted.width), height: ceil(fitted.height))
    }
}
