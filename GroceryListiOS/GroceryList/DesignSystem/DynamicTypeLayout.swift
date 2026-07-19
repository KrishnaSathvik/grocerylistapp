import SwiftUI
import UIKit

/// Shared Dynamic Type layout decisions for accessibility reflow.
enum DynamicTypeLayout {
    /// When true, prefer vertically reflowed layouts over compact horizontal rows.
    static func usesAccessibilityLayout(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    /// Compact large-title hero vs accessibility screen title.
    static func usesCompactScreenTitle(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    /// List-detail header switches to a two-row control/title stack.
    static func usesStackedListHeader(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    /// Settings accessories move below title/subtitle.
    static func usesStackedSettingsAccessories(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    /// Item-row quantity controls move below the title line.
    static func usesStackedItemControls(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    static func essentialLineLimit(for size: DynamicTypeSize, regular: Int = 2) -> Int? {
        usesAccessibilityLayout(size) ? nil : regular
    }

    static func metadataLineLimit(for size: DynamicTypeSize, regular: Int = 1) -> Int? {
        usesAccessibilityLayout(size) ? 3 : regular
    }
}

extension View {
    /// Prefer natural wrapping for essential labels at accessibility sizes.
    @ViewBuilder
    func essentialTextLayout(
        dynamicTypeSize: DynamicTypeSize,
        regularLineLimit: Int = 2
    ) -> some View {
        let limit = DynamicTypeLayout.essentialLineLimit(
            for: dynamicTypeSize,
            regular: regularLineLimit
        )
        if let limit {
            self
                .lineLimit(limit)
                .truncationMode(.tail)
                .layoutPriority(1)
        } else {
            self
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }
}

/// Builds attributed essential labels with hyphenation disabled and word wrapping.
enum EssentialText {
    /// Shared paragraph style for SwiftUI `Text` and UIKit `UILabel` bridges.
    static func wordWrappingParagraphStyle() -> NSMutableParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.hyphenationFactor = 0
        paragraph.lineBreakMode = .byWordWrapping
        // `.standard` may still insert soft hyphens at accessibility sizes.
        paragraph.lineBreakStrategy = []
        return paragraph
    }

    static func attributed(_ string: String) -> AttributedString {
        var attributed = AttributedString(string)
        guard !attributed.characters.isEmpty else { return attributed }

        var container = AttributeContainer()
        container.paragraphStyle = wordWrappingParagraphStyle()
        attributed.mergeAttributes(container)
        return attributed
    }

    /// UIKit path used by `EssentialWordWrappingText` / `UILabel`.
    static func nsAttributed(
        _ string: String,
        font: UIFont,
        color: UIColor,
        strikethrough: Bool = false
    ) -> NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: wordWrappingParagraphStyle(),
        ]
        if strikethrough {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            attributes[.strikethroughColor] = color
        }
        return NSAttributedString(string: string, attributes: attributes)
    }
}
