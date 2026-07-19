import XCTest
import CoreGraphics
@testable import GroceryList

final class ItemRowFitGeometryTests: XCTestCase {
    /// Measured list-card content widths (card − 28 pt ItemRow horizontal padding).
    private let iPhone17ContentWidth: CGFloat = 325
    private let proMaxContentWidth: CGFloat = 355

    private func requiredInlineWidth(
        hasThumbnail: Bool,
        hasEdit: Bool,
        hasStepper: Bool,
        titleIdeal: CGFloat
    ) -> CGFloat {
        ItemRowFitGeometry.inlineRequiredWidth(
            hasThumbnail: hasThumbnail,
            hasEdit: hasEdit,
            hasStepper: hasStepper,
            titleIdealWidth: titleIdeal
        )
    }

    func testProtectedTitleWidthUsesIdealWhenBetweenFloorAndCap() {
        let width = ItemRowFitGeometry.protectedTitleWidth(
            oneLineIdealWidth: 120,
            baselineFloor: ItemRowFitGeometry.baselineTitleFloor,
            maximumInlineAllowance: 220
        )
        XCTAssertEqual(width, 120, accuracy: 0.001)
    }

    func testProtectedTitleWidthRespectsBaselineFloor() {
        let width = ItemRowFitGeometry.protectedTitleWidth(
            oneLineIdealWidth: 40,
            baselineFloor: ItemRowFitGeometry.baselineTitleFloor,
            maximumInlineAllowance: 220
        )
        XCTAssertEqual(width, ItemRowFitGeometry.baselineTitleFloor, accuracy: 0.001)
    }

    func testProtectedTitleWidthRespectsMaximumAllowance() {
        let width = ItemRowFitGeometry.protectedTitleWidth(
            oneLineIdealWidth: 400,
            baselineFloor: ItemRowFitGeometry.baselineTitleFloor,
            maximumInlineAllowance: 220
        )
        XCTAssertEqual(width, 220, accuracy: 0.001)
    }

    func testSelectCandidatePrefersInlineWhenWidthAllows() {
        let candidate = ItemRowFitGeometry.selectCandidate(
            proposedWidth: 390,
            inlineRequiredWidth: 360,
            splitRequiredWidth: 300
        )
        XCTAssertEqual(candidate, .inline)
    }

    func testSelectCandidateChoosesSplitOnePointBelowInline() {
        let candidate = ItemRowFitGeometry.selectCandidate(
            proposedWidth: 359,
            inlineRequiredWidth: 360,
            splitRequiredWidth: 300
        )
        XCTAssertEqual(candidate, .splitStepper)
    }

    func testSelectCandidateChoosesStackedWhenSplitAlsoFails() {
        let candidate = ItemRowFitGeometry.selectCandidate(
            proposedWidth: 280,
            inlineRequiredWidth: 360,
            splitRequiredWidth: 300
        )
        XCTAssertEqual(candidate, .stackedControls)
    }

    func testSelectCandidateBoundaryExactlyAtInlineMinimum() {
        let candidate = ItemRowFitGeometry.selectCandidate(
            proposedWidth: 360,
            inlineRequiredWidth: 360,
            splitRequiredWidth: 300
        )
        XCTAssertEqual(candidate, .inline)
    }

    func testInlineRequiredWidthIncludesProtectedTitleAndChrome() {
        let protected = ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: 40)
        XCTAssertEqual(protected, ItemRowFitGeometry.baselineTitleFloor, accuracy: 0.001)

        let checkbox: CGFloat = 44
        let thumbnail: CGFloat = 38
        let stepper: CGFloat = 88
        let edit: CGFloat = 44
        let spacing: CGFloat = 10

        let inlineRequired = ItemRowFitGeometry.inlineRequiredWidth(
            checkboxWidth: checkbox,
            thumbnailWidth: thumbnail,
            protectedTitleWidth: protected,
            stepperWidth: stepper,
            editWidth: edit,
            spacing: spacing
        )
        // 5 present slots → 4 gaps: 44+38+68+88+44 + 40 = 322
        XCTAssertEqual(inlineRequired, 322, accuracy: 0.001)

        let splitRequired = ItemRowFitGeometry.splitRequiredWidth(
            checkboxWidth: checkbox,
            thumbnailWidth: thumbnail,
            protectedTitleWidth: protected,
            editWidth: edit,
            spacing: spacing
        )
        // 4 present slots → 3 gaps: 44+38+68+44 + 30 = 224
        XCTAssertEqual(splitRequired, 224, accuracy: 0.001)

        let candidate = ItemRowFitGeometry.selectCandidate(
            proposedWidth: inlineRequired - 1,
            inlineRequiredWidth: inlineRequired,
            splitRequiredWidth: splitRequired
        )
        XCTAssertEqual(candidate, .splitStepper)
    }

    func testOptionalChromeOmittedFromRequiredWidthGaps() {
        let protected = ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: 40)
        let inlineRequired = ItemRowFitGeometry.inlineRequiredWidth(
            checkboxWidth: 44,
            thumbnailWidth: 0,
            protectedTitleWidth: protected,
            stepperWidth: 88,
            editWidth: 0,
            spacing: 10
        )
        // checkbox + title + stepper → 2 gaps: 44+68+88 + 20 = 220
        XCTAssertEqual(inlineRequired, 220, accuracy: 0.001)

        let splitRequired = ItemRowFitGeometry.splitRequiredWidth(
            checkboxWidth: 44,
            thumbnailWidth: 0,
            protectedTitleWidth: protected,
            editWidth: 0,
            spacing: 10
        )
        // checkbox + title → 1 gap: 44+68 + 10 = 122
        XCTAssertEqual(splitRequired, 122, accuracy: 0.001)
    }

    func testMissingThumbnailLowersInlineRequirement() {
        let withThumb = requiredInlineWidth(hasThumbnail: true, hasEdit: true, hasStepper: true, titleIdeal: 80)
        let withoutThumb = requiredInlineWidth(hasThumbnail: false, hasEdit: true, hasStepper: true, titleIdeal: 80)
        XCTAssertLessThan(withoutThumb, withThumb)
        XCTAssertEqual(
            ItemRowFitGeometry.selectCandidate(
                proposedWidth: withoutThumb,
                inlineRequiredWidth: withoutThumb,
                splitRequiredWidth: withoutThumb - ItemRowFitGeometry.Chrome.stepperWidth
            ),
            .inline
        )
    }

    func testHidingEditLowersInlineRequirement() {
        let withEdit = requiredInlineWidth(hasThumbnail: true, hasEdit: true, hasStepper: true, titleIdeal: 80)
        let withoutEdit = requiredInlineWidth(hasThumbnail: true, hasEdit: false, hasStepper: true, titleIdeal: 80)
        XCTAssertLessThan(withoutEdit, withEdit)
    }

    func testNoStepperDoesNotReserveStepperChrome() {
        let withStepper = requiredInlineWidth(hasThumbnail: true, hasEdit: true, hasStepper: true, titleIdeal: 80)
        let withoutStepper = requiredInlineWidth(hasThumbnail: true, hasEdit: true, hasStepper: false, titleIdeal: 80)
        XCTAssertLessThan(withoutStepper, withStepper)
    }

    // MARK: - Title-only floor (metadata must not inflate protected title)

    func testProtectedTitleUsesTitleIdealOnlyIgnoringWideMetadata() {
        // Short product title (~Orange); wide metadata chips must not be passed in.
        let titleIdeal: CGFloat = 65
        let wideMetadataIdeal: CGFloat = 168 // e.g. "Produce · Walmart"

        let protectedFromTitle = ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: titleIdeal)
        XCTAssertEqual(protectedFromTitle, ItemRowFitGeometry.baselineTitleFloor, accuracy: 0.001)

        // Document the failure mode: feeding metadata ideal into protectedTitleWidth
        // would incorrectly raise the floor and reject Candidate A on measured content widths.
        let protectedIfMetadataInflated = ItemRowFitGeometry.protectedTitleWidth(
            oneLineIdealWidth: wideMetadataIdeal
        )
        XCTAssertEqual(protectedIfMetadataInflated, wideMetadataIdeal, accuracy: 0.001)
        XCTAssertGreaterThan(protectedIfMetadataInflated, protectedFromTitle)
    }

    func testTitleSlotMinimumWidthDoesNotRaiseWhenMetadataNarrowerThanProtected() {
        let protected = ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: 65)
        let slot = ItemRowFitGeometry.titleSlotMinimumWidth(
            protectedTitleWidth: protected,
            metadataMinWidth: 60 // category pill-sized min below protected floor
        )
        XCTAssertEqual(slot, protected, accuracy: 0.001)
    }

    func testTitleSlotMinimumWidthRaisesOnlyForUnbreakableMetadata() {
        let protected = ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: 65)
        let slot = ItemRowFitGeometry.titleSlotMinimumWidth(
            protectedTitleWidth: protected,
            metadataMinWidth: 140
        )
        XCTAssertEqual(slot, 140, accuracy: 0.001)
    }

    func testOrangeScaleTitleSelectsInlineAtMeasuredContentWidths() {
        // Orange / Grapes / Mango scale ideal (~60–70) + floor → A on 325 and 355.
        let titleIdeal: CGFloat = 65
        let protected = ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: titleIdeal)
        XCTAssertEqual(protected, ItemRowFitGeometry.baselineTitleFloor, accuracy: 0.001)

        let inlineRequired = requiredInlineWidth(
            hasThumbnail: true,
            hasEdit: true,
            hasStepper: true,
            titleIdeal: titleIdeal
        )
        // 44+38+68+88+44 + 4*10 = 322
        XCTAssertEqual(inlineRequired, 322, accuracy: 0.001)
        XCTAssertLessThanOrEqual(inlineRequired, iPhone17ContentWidth)
        XCTAssertLessThanOrEqual(inlineRequired, proMaxContentWidth)

        XCTAssertEqual(
            ItemRowFitGeometry.selectCandidate(
                proposedWidth: iPhone17ContentWidth,
                inlineRequiredWidth: inlineRequired,
                splitRequiredWidth: 224
            ),
            .inline
        )
        XCTAssertEqual(
            ItemRowFitGeometry.selectCandidate(
                proposedWidth: proMaxContentWidth,
                inlineRequiredWidth: inlineRequired,
                splitRequiredWidth: 224
            ),
            .inline
        )
    }

    func testLongerTitleIdealSelectsSplitOnIPhone17ContentWidth() {
        // Long names still leave A: protected rises with ideal (120 > floor).
        let titleIdeal: CGFloat = 120
        let inlineRequired = requiredInlineWidth(
            hasThumbnail: true,
            hasEdit: true,
            hasStepper: true,
            titleIdeal: titleIdeal
        )
        // 44+38+120+88+44 + 40 = 374
        XCTAssertEqual(inlineRequired, 374, accuracy: 0.001)
        XCTAssertGreaterThan(inlineRequired, iPhone17ContentWidth)
        XCTAssertEqual(
            ItemRowFitGeometry.selectCandidate(
                proposedWidth: iPhone17ContentWidth,
                inlineRequiredWidth: inlineRequired,
                splitRequiredWidth: inlineRequired - ItemRowFitGeometry.Chrome.stepperWidth
            ),
            .splitStepper
        )
    }

    func testWideMetadataIdealWouldRejectAOnIPhone17ContentWidth() {
        // Proves why title-only measurement is required: metadata-inflated floor fails 325.
        let titleIdeal: CGFloat = 168
        let inflatedInline = requiredInlineWidth(
            hasThumbnail: true,
            hasEdit: true,
            hasStepper: true,
            titleIdeal: titleIdeal
        )
        let splitRequired = ItemRowFitGeometry.splitRequiredWidth(
            checkboxWidth: ItemRowFitGeometry.Chrome.checkboxWidth,
            thumbnailWidth: ItemRowFitGeometry.Chrome.thumbnailWidth,
            protectedTitleWidth: ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: titleIdeal),
            editWidth: ItemRowFitGeometry.Chrome.editWidth,
            spacing: ItemRowFitGeometry.Chrome.spacing
        )
        XCTAssertGreaterThan(inflatedInline, iPhone17ContentWidth)
        XCTAssertEqual(
            ItemRowFitGeometry.selectCandidate(
                proposedWidth: iPhone17ContentWidth,
                inlineRequiredWidth: inflatedInline,
                splitRequiredWidth: splitRequired
            ),
            .splitStepper
        )
    }

    // MARK: - Stepper chrome + no lying metadata demotion

    func testChromeStepperWidthIsEightyEight() {
        // QuantityStepper must report this layout width (44×44 hits share the capsule).
        XCTAssertEqual(ItemRowFitGeometry.Chrome.stepperWidth, 88, accuracy: 0.001)
    }

    func testCandidateASelectableAtChromeFloorWhenProposedAtLeastThreeTwentyTwo() {
        // protected=68, chrome 44+38+88+44+4×10 = 322
        let protected = ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: 40)
        XCTAssertEqual(protected, 68, accuracy: 0.001)

        let inlineRequired = ItemRowFitGeometry.inlineRequiredWidth(
            checkboxWidth: ItemRowFitGeometry.Chrome.checkboxWidth,
            thumbnailWidth: ItemRowFitGeometry.Chrome.thumbnailWidth,
            protectedTitleWidth: protected,
            stepperWidth: ItemRowFitGeometry.Chrome.stepperWidth,
            editWidth: ItemRowFitGeometry.Chrome.editWidth,
            spacing: ItemRowFitGeometry.Chrome.spacing
        )
        XCTAssertEqual(inlineRequired, 322, accuracy: 0.001)

        XCTAssertEqual(
            ItemRowFitGeometry.selectCandidate(
                proposedWidth: 322,
                inlineRequiredWidth: inlineRequired,
                splitRequiredWidth: 224
            ),
            .inline
        )
        XCTAssertEqual(
            ItemRowFitGeometry.selectCandidate(
                proposedWidth: 321,
                inlineRequiredWidth: inlineRequired,
                splitRequiredWidth: 224
            ),
            .splitStepper
        )
    }

    func testWideMetadataIdealMustNotDemoteAViaLyingProbe() {
        // AdaptiveItemRowLayout must not feed ViewThatFits wide ideals into demotion.
        // Policy: titleSlot uses title-only protected + metadataMinWidth 0.
        let protected = ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: 65)
        let wideMetadataIdeal: CGFloat = 168 // "Produce · Walmart" style ideal

        let honestTitleSlot = ItemRowFitGeometry.titleSlotMinimumWidth(
            protectedTitleWidth: protected,
            metadataMinWidth: 0
        )
        XCTAssertEqual(honestTitleSlot, protected, accuracy: 0.001)

        let inlineRequired = ItemRowFitGeometry.inlineRequiredWidth(
            checkboxWidth: ItemRowFitGeometry.Chrome.checkboxWidth,
            thumbnailWidth: ItemRowFitGeometry.Chrome.thumbnailWidth,
            protectedTitleWidth: honestTitleSlot,
            stepperWidth: ItemRowFitGeometry.Chrome.stepperWidth,
            editWidth: ItemRowFitGeometry.Chrome.editWidth,
            spacing: ItemRowFitGeometry.Chrome.spacing
        )
        XCTAssertEqual(
            ItemRowFitGeometry.selectCandidate(
                proposedWidth: iPhone17ContentWidth,
                inlineRequiredWidth: inlineRequired,
                splitRequiredWidth: 224
            ),
            .inline
        )

        // Contrast: treating the wide ideal as an unbreakable min would wrongly reject A.
        let lyingSlot = ItemRowFitGeometry.titleSlotMinimumWidth(
            protectedTitleWidth: protected,
            metadataMinWidth: wideMetadataIdeal
        )
        let lyingInline = ItemRowFitGeometry.inlineRequiredWidth(
            checkboxWidth: ItemRowFitGeometry.Chrome.checkboxWidth,
            thumbnailWidth: ItemRowFitGeometry.Chrome.thumbnailWidth,
            protectedTitleWidth: lyingSlot,
            stepperWidth: ItemRowFitGeometry.Chrome.stepperWidth,
            editWidth: ItemRowFitGeometry.Chrome.editWidth,
            spacing: ItemRowFitGeometry.Chrome.spacing
        )
        let lyingSplit = ItemRowFitGeometry.splitRequiredWidth(
            checkboxWidth: ItemRowFitGeometry.Chrome.checkboxWidth,
            thumbnailWidth: ItemRowFitGeometry.Chrome.thumbnailWidth,
            protectedTitleWidth: lyingSlot,
            editWidth: ItemRowFitGeometry.Chrome.editWidth,
            spacing: ItemRowFitGeometry.Chrome.spacing
        )
        XCTAssertGreaterThan(lyingInline, iPhone17ContentWidth)
        XCTAssertEqual(
            ItemRowFitGeometry.selectCandidate(
                proposedWidth: iPhone17ContentWidth,
                inlineRequiredWidth: lyingInline,
                splitRequiredWidth: lyingSplit
            ),
            .splitStepper
        )
    }
}
