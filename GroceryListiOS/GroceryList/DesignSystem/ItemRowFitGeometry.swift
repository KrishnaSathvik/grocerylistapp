import CoreGraphics

/// Stage 1 geometry-only candidate pick result (no SwiftUI / Dynamic Type).
/// Stage 2 broader extraction is paused until revised Candidate B is reviewed.
enum ItemRowCandidate: Equatable {
    case inline
    case splitStepper
    case stackedControls
}

/// Pure helpers: protected title width, required chrome widths, candidate selection.
/// Candidate B = title|edit on the primary line; category|stepper on the secondary line
/// (stepper is not a full-width third row).
enum ItemRowFitGeometry {
    /// Minimum protected title width for Candidate A selection.
    /// Tuned from measured list-card content widths (iPhone 17 ≈ 325 pt, Pro Max ≈ 355 pt
    /// after card − 28 pt ItemRow horizontal padding), not from font-size thresholds.
    /// With chrome 44+38+88+44+40 = 254, floor 68 → inlineRequired 322, so short titles
    /// can select A on both devices while long ideals still raise the protected width.
    static let baselineTitleFloor: CGFloat = 68
    static let maximumInlineTitleAllowance: CGFloat = 220

    /// Representative default-Large chrome widths for geometry tests and planning.
    /// Matches measured ItemRow intrinsics: 44 pt tap targets, 38 pt thumbnail, 88 pt stepper capsule.
    enum Chrome {
        static let checkboxWidth: CGFloat = 44
        static let thumbnailWidth: CGFloat = 38
        static let stepperWidth: CGFloat = 88
        /// Visible capsule height; tap targets stay 44×44 inside QuantityStepper.
        static let stepperVisualHeight: CGFloat = 28
        static let editWidth: CGFloat = 44
        static let spacing: CGFloat = 10
    }

    /// Candidate A width for a row with optional thumbnail, stepper, and edit slots.
    static func inlineRequiredWidth(
        hasThumbnail: Bool,
        hasEdit: Bool,
        hasStepper: Bool,
        titleIdealWidth: CGFloat,
        spacing: CGFloat = Chrome.spacing
    ) -> CGFloat {
        let protected = protectedTitleWidth(oneLineIdealWidth: titleIdealWidth)
        return inlineRequiredWidth(
            checkboxWidth: Chrome.checkboxWidth,
            thumbnailWidth: hasThumbnail ? Chrome.thumbnailWidth : 0,
            protectedTitleWidth: protected,
            stepperWidth: hasStepper ? Chrome.stepperWidth : 0,
            editWidth: hasEdit ? Chrome.editWidth : 0,
            spacing: spacing
        )
    }

    /// One-line title floor from the **product title label only**.
    /// Do not pass metadata ideal width here — wide chips must not inflate this floor.
    static func protectedTitleWidth(
        oneLineIdealWidth: CGFloat,
        baselineFloor: CGFloat = baselineTitleFloor,
        maximumInlineAllowance: CGFloat = maximumInlineTitleAllowance
    ) -> CGFloat {
        min(max(oneLineIdealWidth, baselineFloor), maximumInlineAllowance)
    }

    /// Title-region slot floor for candidate width checks.
    /// Starts from the title-only protected width; raises only when callers pass a
    /// **trustworthy** unbreakable metadata minimum (e.g. a known compact pill width).
    /// Do not pass ViewThatFits `sizeThatFits(width: 0)` ideals — those often return the
    /// wide line and dishonestly demote Candidate A. Prefer `metadataMinWidth: 0` and let
    /// metadata compact inside the title column.
    static func titleSlotMinimumWidth(
        protectedTitleWidth: CGFloat,
        metadataMinWidth: CGFloat
    ) -> CGFloat {
        max(protectedTitleWidth, metadataMinWidth)
    }

    static func selectCandidate(
        proposedWidth: CGFloat,
        inlineRequiredWidth: CGFloat,
        splitRequiredWidth: CGFloat
    ) -> ItemRowCandidate {
        if proposedWidth >= inlineRequiredWidth {
            return .inline
        }
        if proposedWidth >= splitRequiredWidth {
            return .splitStepper
        }
        return .stackedControls
    }

    /// Candidate A: checkbox | thumbnail? | protected title | stepper? | edit?
    /// Spacing is applied only between present (positive-width) slots.
    static func inlineRequiredWidth(
        checkboxWidth: CGFloat,
        thumbnailWidth: CGFloat = 0,
        protectedTitleWidth: CGFloat,
        stepperWidth: CGFloat = 0,
        editWidth: CGFloat = 0,
        spacing: CGFloat
    ) -> CGFloat {
        requiredWidth(
            widths: [checkboxWidth, thumbnailWidth, protectedTitleWidth, stepperWidth, editWidth],
            spacing: spacing
        )
    }

    /// Candidate B top row: checkbox | thumbnail? | protected title | edit?
    /// Stepper shares the metadata/secondary line inside the title column and does
    /// not contribute to this top-row width requirement.
    static func splitRequiredWidth(
        checkboxWidth: CGFloat,
        thumbnailWidth: CGFloat = 0,
        protectedTitleWidth: CGFloat,
        editWidth: CGFloat = 0,
        spacing: CGFloat
    ) -> CGFloat {
        requiredWidth(
            widths: [checkboxWidth, thumbnailWidth, protectedTitleWidth, editWidth],
            spacing: spacing
        )
    }

    static func requiredWidth(widths: [CGFloat], spacing: CGFloat) -> CGFloat {
        let present = widths.filter { $0 > 0 }
        guard !present.isEmpty else { return 0 }
        let gapCount = CGFloat(present.count - 1)
        return present.reduce(0, +) + spacing * gapCount
    }
}
