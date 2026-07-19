import XCTest
import SwiftUI
import UIKit
@testable import GroceryList

final class DynamicTypeLayoutTests: XCTestCase {
    func testRegularSizesDoNotUseAccessibilityLayout() {
        let regular: [DynamicTypeSize] = [
            .xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge,
        ]
        for size in regular {
            XCTAssertFalse(
                DynamicTypeLayout.usesAccessibilityLayout(size),
                "\(size) should keep compact layout"
            )
            XCTAssertFalse(DynamicTypeLayout.usesStackedItemControls(size))
            XCTAssertFalse(DynamicTypeLayout.usesStackedListHeader(size))
            XCTAssertFalse(DynamicTypeLayout.usesStackedSettingsAccessories(size))
            XCTAssertFalse(DynamicTypeLayout.usesCompactScreenTitle(size))
        }
    }

    func testAccessibilitySizesUseReflowLayouts() {
        let accessibility: [DynamicTypeSize] = [
            .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5,
        ]
        for size in accessibility {
            XCTAssertTrue(
                DynamicTypeLayout.usesAccessibilityLayout(size),
                "\(size) should reflow"
            )
            XCTAssertTrue(DynamicTypeLayout.usesStackedItemControls(size))
            XCTAssertTrue(DynamicTypeLayout.usesStackedListHeader(size))
            XCTAssertTrue(DynamicTypeLayout.usesStackedSettingsAccessories(size))
            XCTAssertTrue(DynamicTypeLayout.usesCompactScreenTitle(size))
        }
    }

    func testEssentialLineLimitsRelaxAtAccessibilitySizes() {
        XCTAssertEqual(DynamicTypeLayout.essentialLineLimit(for: .large), 2)
        XCTAssertEqual(DynamicTypeLayout.essentialLineLimit(for: .xxxLarge), 2)
        XCTAssertNil(DynamicTypeLayout.essentialLineLimit(for: .accessibility1))
        XCTAssertNil(DynamicTypeLayout.essentialLineLimit(for: .accessibility5))
    }

    func testMetadataLineLimitsExpandAtAccessibilitySizes() {
        XCTAssertEqual(DynamicTypeLayout.metadataLineLimit(for: .large), 1)
        XCTAssertEqual(DynamicTypeLayout.metadataLineLimit(for: .accessibility1), 3)
    }

    func testAdaptiveTypographySelectionTracksAccessibilityMode() {
        XCTAssertFalse(DynamicTypeLayout.usesCompactScreenTitle(.xxxLarge))
        XCTAssertTrue(DynamicTypeLayout.usesCompactScreenTitle(.accessibility1))
        _ = AppTypography.topLevelScreenTitle(for: .large)
        _ = AppTypography.topLevelScreenTitle(for: .accessibility1)
        _ = AppTypography.adaptiveCardTitle(for: .large)
        _ = AppTypography.adaptiveCardTitle(for: .accessibility3)
    }

    func testEssentialTextPreservesContentAndDisablesHyphenation() {
        let attributed = EssentialText.attributed("Orange")
        XCTAssertEqual(String(attributed.characters), "Orange")
        var foundHyphenation = false
        for run in attributed.runs {
            if let style = run.paragraphStyle {
                XCTAssertEqual(style.hyphenationFactor, 0, accuracy: 0.001)
                foundHyphenation = true
            }
        }
        XCTAssertTrue(foundHyphenation, "Expected paragraph style with hyphenationFactor 0")
    }

    func testWordWrappingParagraphStyleDisablesHyphenation() {
        let style = EssentialText.wordWrappingParagraphStyle()
        XCTAssertEqual(style.hyphenationFactor, 0, accuracy: 0.001)
        XCTAssertEqual(style.lineBreakMode, .byWordWrapping)
    }

    func testEssentialTextNSAttributedMatchesUILabelBridgeContract() {
        let font = AppTypography.itemTitleUIFont()
        let attributed = EssentialText.nsAttributed(
            "Strawberries",
            font: font,
            color: .label,
            strikethrough: false
        )
        XCTAssertEqual(attributed.string, "Strawberries")

        var foundParagraph = false
        attributed.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attributed.length)) { value, _, _ in
            guard let style = value as? NSParagraphStyle else { return }
            XCTAssertEqual(style.hyphenationFactor, 0, accuracy: 0.001)
            XCTAssertEqual(style.lineBreakMode, .byWordWrapping)
            foundParagraph = true
        }
        XCTAssertTrue(foundParagraph)

        // Representable wrapper exists and is constructible for ItemRow titles.
        _ = EssentialWordWrappingText(text: "Strawberries", color: .primary, isStrikethrough: false)
    }

    func testLayoutHelpersDoNotMutateSettings() {
        let before = AppSettings.activeListId
        _ = DynamicTypeLayout.usesStackedItemControls(.accessibility1)
        _ = DynamicTypeLayout.usesStackedListHeader(.large)
        XCTAssertEqual(AppSettings.activeListId, before)
    }
}
