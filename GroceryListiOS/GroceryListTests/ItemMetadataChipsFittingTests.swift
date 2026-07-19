import XCTest
import SwiftUI
import UIKit
@testable import GroceryList

/// Regression: category metadata must not report a width wider than the slot beside the
/// quantity stepper. `fixedSize(horizontal: true)` overflow was painting under − 1 +.
@MainActor
final class ItemMetadataChipsFittingTests: XCTestCase {
    /// Typical Candidate B metadata max width on iPhone 17 content (~325):
    /// title column ≈ 169, minus 88 stepper and 10 spacing → ~71.
    private let narrowMetadataSlot: CGFloat = 72

    func testFullCategoryMetadataFitsWithinNarrowSlotBesideStepper() {
        let item = GroceryItem(name: "Pasta", categoryId: "pantry")
        let chips = ItemMetadataChips(
            item: item,
            mode: .full,
            categories: [],
            stores: [],
            onSelectCategory: { _ in },
            onSelectStore: { _ in }
        )

        let host = UIHostingController(rootView: chips)
        let fitted = host.sizeThatFits(
            in: CGSize(width: narrowMetadataSlot, height: UIView.layoutFittingExpandedSize.height)
        )

        XCTAssertLessThanOrEqual(
            fitted.width,
            narrowMetadataSlot + 0.5,
            "Pantry & Grains must compress/truncate to the metadata slot beside the stepper; got \(fitted.width)"
        )
    }

    func testLongCategoryLabelsExceedUnconstrainedIdealWidth() {
        // Documents why a truncating fallback is required — ideal widths won't fit B.
        let font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.medium)
        let labels = [
            "Pantry & Grains",
            "Meat & Poultry",
            "Health & Beauty",
            "Condiments & Spices",
        ]
        for label in labels {
            let ideal = (label as NSString)
                .size(withAttributes: [.font: font])
                .width
            XCTAssertGreaterThan(
                ideal,
                narrowMetadataSlot,
                "\(label) ideal \(ideal) should exceed the narrow stepper-adjacent slot"
            )
        }
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight],
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
