#if DEBUG
import SwiftUI

/// DEBUG-only Stage 1 closure harness for optional-content + reliable RTL review.
/// Launch: `-Stage1ItemRowReview` with optional `-Stage1ReviewScene=optional|candidates|rtl`
enum Stage1ItemRowReviewLaunch {
    static let argument = "-Stage1ItemRowReview"
    static let sceneArgumentPrefix = "-Stage1ReviewScene="

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
    }

    static var scene: Stage1ItemRowReviewHarness.Scene {
        let args = ProcessInfo.processInfo.arguments
        if let raw = args.first(where: { $0.hasPrefix(sceneArgumentPrefix) }) {
            let value = String(raw.dropFirst(sceneArgumentPrefix.count)).lowercased()
            switch value {
            case "candidates": return .candidates
            case "rtl": return .rtl
            case "optional2", "optional-more", "optionalmore": return .optionalStatesMore
            case "breview", "b-review", "candidateb": return .candidateBReview
            default: return .optionalStates
            }
        }
        if args.contains("-Stage1ItemRowRTL") {
            return .rtl
        }
        return .optionalStates
    }
}

struct Stage1ItemRowReviewHarness: View {
    enum Scene: String {
        case optionalStates
        case optionalStatesMore
        case candidates
        case candidateBReview
        case rtl
    }

    var scene: Scene = .optionalStates

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch scene {
                    case .optionalStates:
                        optionalStatesContent
                    case .optionalStatesMore:
                        optionalStatesMoreContent
                    case .candidates:
                        candidatesContent
                    case .candidateBReview:
                        candidateBReviewContent
                    case .rtl:
                        rtlContent
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.dynamicTypeSize, .large)
        .environment(\.itemRowShowCandidateBadge, true)
        // Reliable RTL: environment layoutDirection only. Do not also set
        // itemRowForceMirror — Layout bounds are leading-origin, so a second flip
        // undoes RTL and looks like LTR again.
        .environment(\.layoutDirection, scene == .rtl ? .rightToLeft : .leftToRight)
        .accessibilityIdentifier("stage1-itemrow-review-\(scene.rawValue)")
    }

    private var navigationTitle: String {
        switch scene {
        case .optionalStates: return "Stage1 Optional"
        case .optionalStatesMore: return "Stage1 Optional 2"
        case .candidates: return "Stage1 Candidates"
        case .candidateBReview: return "Stage1 B Review"
        case .rtl: return "Stage1 RTL"
        }
    }

    // MARK: - Scenes

    @ViewBuilder
    private var optionalStatesContent: some View {
        section("1 · Normal active", id: "stage1-optional-normal") {
            reviewRow(
                name: "Orange",
                storeId: "walmart",
                quantity: 2
            )
        }

        section("2 · Completed (styling only)", id: "stage1-optional-completed") {
            reviewRow(
                name: "Orange",
                storeId: "walmart",
                quantity: 2,
                isCompleted: true
            )
        }

        section("3 · Selection selected / unselected", id: "stage1-optional-selection") {
            reviewRow(
                name: "Grapes",
                storeId: "walmart",
                isSelectionMode: true,
                isSelected: true,
                showsEditButton: false
            )
            reviewRow(
                name: "Cabbage",
                storeId: "walmart",
                isSelectionMode: true,
                isSelected: false,
                showsEditButton: false
            )
        }

        section("4 · No thumbnail", id: "stage1-optional-no-thumbnail") {
            reviewRow(
                name: "Orange",
                storeId: "walmart",
                forceHideThumbnail: true
            )
        }

        section("5 · Edit hidden", id: "stage1-optional-no-edit") {
            reviewRow(
                name: "Grapes",
                storeId: "walmart",
                showsEditButton: false
            )
        }
    }

    @ViewBuilder
    private var optionalStatesMoreContent: some View {
        section("6 · Quantity text (no stepper)", id: "stage1-optional-quantity-text") {
            reviewRow(
                name: "Broccoli",
                storeId: "costco",
                quantityText: "2 lb"
            )
            Text("No empty lower control row when quantity text replaces the stepper.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.inkSecondary)
        }

        section("7 · No store metadata", id: "stage1-optional-no-store") {
            reviewRow(
                name: "Zucchini",
                metadataMode: .categoryOnly
            )
        }

        section("8 · Long metadata", id: "stage1-optional-long-metadata") {
            reviewRow(
                name: "Cucumber",
                categoryId: "produce",
                storeId: "indianbazaar",
                metadataMode: .full
            )
        }

        section("9 · Chicken drumsticks", id: "stage1-optional-chicken") {
            reviewRow(
                name: "Chicken drumsticks",
                categoryId: "meat",
                storeId: "costco"
            )
        }

        section("10 · Hidden edit vs full chrome (A may win sooner)", id: "stage1-optional-edit-compare") {
            labeledRow(label: "full chrome", name: "Grapes", storeId: "walmart")
            VStack(alignment: .leading, spacing: 4) {
                Text("edit hidden")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.accentLink)
                reviewRow(
                    name: "Grapes",
                    storeId: "walmart",
                    showsEditButton: false
                )
            }
        }
    }

    @ViewBuilder
    private var candidatesContent: some View {
        section("Candidate A — fully inline", id: "stage1-candidate-a") {
            labeledRow(label: "expect A", name: "Orange", storeId: "walmart")
            labeledRow(label: "expect A", name: "Grapes", storeId: "walmart")
        }

        section("Candidate B — title|edit / category|stepper", id: "stage1-candidate-b") {
            Text("Stepper shares the metadata line (trailing). No isolated full-width third row.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.inkSecondary)
            labeledRow(
                label: "often B",
                name: "Extra virgin olive oil",
                storeId: "walmart"
            )
            labeledRow(
                label: "may B with metadata",
                name: "Watermelon",
                storeId: "costco"
            )
        }

        section("Candidate C — stacked (narrow frame)", id: "stage1-candidate-c") {
            labeledRow(
                label: "expect C in narrow",
                name: "Unsweetened vanilla almond milk",
                storeId: "costco"
            )
            .frame(maxWidth: 280, alignment: .leading)
        }
    }

    @ViewBuilder
    private var candidateBReviewContent: some View {
        Text("Default Large · revised Candidate B. Expect category and − 1 + on one secondary line; no floating stepper.")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.inkSecondary)

        section("Acceptance set", id: "stage1-b-review-set") {
            reviewRow(name: "Butter", categoryId: "dairy", storeId: "walmart")
            reviewRow(name: "Eggs", categoryId: "dairy", storeId: "walmart")
            reviewRow(name: "Watermelon", categoryId: "produce", storeId: "costco")
            reviewRow(name: "Strawberries", categoryId: "produce", storeId: "costco")
            reviewRow(
                name: "Chicken drumsticks",
                categoryId: "meat",
                storeId: "costco"
            )
        }

        section("Forced B width (narrow column)", id: "stage1-b-review-forced") {
            Text("Same rows at ~320pt content width so B is more likely than A.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.inkSecondary)
            VStack(alignment: .leading, spacing: 8) {
                reviewRow(name: "Watermelon", categoryId: "produce", storeId: "costco")
                reviewRow(
                    name: "Chicken drumsticks",
                    categoryId: "meat",
                    storeId: "costco"
                )
                reviewRow(
                    name: "Extra virgin olive oil",
                    categoryId: "produce",
                    storeId: "walmart"
                )
            }
            .frame(maxWidth: 320, alignment: .leading)
        }
    }

    @ViewBuilder
    private var rtlContent: some View {
        Text("Forced layoutDirection=rightToLeft (not AppleTextDirection). Expect checkbox on trailing/visual-right; edit on leading/visual-left.")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.inkSecondary)
            .accessibilityIdentifier("stage1-rtl-caption")

        Text("layoutDirection=rightToLeft (leading-origin Layout; no manual flip)")
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(AppColors.accentLink)
            .accessibilityIdentifier("stage1-rtl-mirror-flag")

        section("RTL · Active + stepper + edit", id: "stage1-rtl-active") {
            reviewRow(name: "Orange", storeId: "walmart", quantity: 3)
            reviewRow(name: "Grapes", storeId: "walmart", quantity: 1)
        }

        section("RTL · Selection", id: "stage1-rtl-selection") {
            reviewRow(
                name: "Cabbage",
                storeId: "walmart",
                isSelectionMode: true,
                isSelected: true,
                showsEditButton: false
            )
            reviewRow(
                name: "Broccoli",
                storeId: "costco",
                isSelectionMode: true,
                isSelected: false,
                showsEditButton: false
            )
        }

        section("RTL · Metadata + long name", id: "stage1-rtl-metadata") {
            reviewRow(
                name: "Chicken drumsticks",
                categoryId: "meat",
                storeId: "costco"
            )
            reviewRow(
                name: "Extra virgin olive oil",
                storeId: "walmart"
            )
        }

        section("RTL · No thumbnail / quantity text", id: "stage1-rtl-optional-chrome") {
            reviewRow(
                name: "Orange",
                storeId: "walmart",
                forceHideThumbnail: true
            )
            reviewRow(
                name: "Mushrooms",
                storeId: "costco",
                quantityText: "1 pack"
            )
        }
    }

    // MARK: - Helpers

    private func section<Content: View>(
        _ title: String,
        id: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColors.inkSecondary)
                .accessibilityIdentifier("\(id)-label")
            content()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(id)
    }

    private func labeledRow(
        label: String,
        name: String,
        storeId: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.accentLink)
            reviewRow(name: name, storeId: storeId)
        }
    }

    private func reviewRow(
        name: String,
        categoryId: String = "produce",
        storeId: String? = nil,
        quantity: Int = 1,
        quantityText: String? = nil,
        metadataMode: ItemRowMetadataMode = .full,
        isCompleted: Bool = false,
        isSelectionMode: Bool = false,
        isSelected: Bool = false,
        showsEditButton: Bool = true,
        forceHideThumbnail: Bool = false
    ) -> some View {
        let list = GroceryList(name: "Stage1 Review")
        let item = GroceryItem(
            name: name,
            quantityValue: quantityText == nil ? quantity : nil,
            quantityText: quantityText,
            categoryId: categoryId,
            storeId: storeId,
            isCompleted: isCompleted,
            sortOrder: 0,
            list: list
        )

        return ItemRow(
            item: item,
            metadataMode: metadataMode,
            categories: CategoryService.allCategories(),
            stores: [
                StoreService.StoreInfo(
                    id: "walmart",
                    label: "Walmart",
                    domain: nil,
                    colorHex: "#0071CE",
                    iconSymbol: nil,
                    isCustom: false,
                    sortOrder: 0
                ),
                StoreService.StoreInfo(
                    id: "costco",
                    label: "Costco",
                    domain: nil,
                    colorHex: "#E31837",
                    iconSymbol: nil,
                    isCustom: false,
                    sortOrder: 1
                ),
                StoreService.StoreInfo(
                    id: "indianbazaar",
                    label: "Indian Bazaar Super Market",
                    domain: nil,
                    colorHex: "#C45C26",
                    iconSymbol: nil,
                    isCustom: false,
                    sortOrder: 2
                ),
            ],
            isCompleted: isCompleted,
            isSelectionMode: isSelectionMode,
            isSelected: isSelected,
            showsEditButton: showsEditButton,
            forceHideThumbnail: forceHideThumbnail,
            onToggle: {},
            onIncrement: {},
            onDecrement: {},
            onShowActions: {}
        )
    }
}
#endif
