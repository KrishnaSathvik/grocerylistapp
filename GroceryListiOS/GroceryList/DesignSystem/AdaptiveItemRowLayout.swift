import SwiftUI

/// Stage 1/2 ItemRow content-fit layout. Geometry helpers live in `ItemRowFitGeometry`;
/// role tags live in `ItemRowLayoutRoles`.
struct AdaptiveItemRowLayout: Layout {
    var spacing: CGFloat = 10
    /// Vertical gap between title label and metadata inside the title region.
    var titleMetadataSpacing: CGFloat = 4
    /// When true, flip LTR plan x-positions inside a left-origin coordinate space.
    /// Leave false under `layoutDirection == .rightToLeft` — Layout bounds are
    /// leading-origin, so an LTR plan (checkbox at x=0) already sits on visual trailing
    /// without a second flip.
    var mirrorsHorizontally: Bool = false
    var baselineTitleFloor: CGFloat = ItemRowFitGeometry.baselineTitleFloor
    var maximumInlineTitleAllowance: CGFloat = ItemRowFitGeometry.maximumInlineTitleAllowance
    var candidateAMinHeight: CGFloat = AppSpacing.rowMinHeight
    /// Candidate B stays near A height for one-line titles (metadata + stepper share one line).
    var candidateBMinHeight: CGFloat = AppSpacing.rowMinHeight
    var candidateCMinHeight: CGFloat = 120

    struct Cache {
        var checkboxSize: CGSize = .zero
        var thumbnailSize: CGSize = .zero
        /// Ideal size of the product title label only (not metadata).
        var titleIdealSize: CGSize = .zero
        var stepperSize: CGSize = .zero
        var editSize: CGSize = .zero
        var hasCheckbox = false
        var hasThumbnail = false
        var hasTitle = false
        var hasMetadata = false
        var hasStepper = false
        var hasEdit = false
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        measureIntrinsics(subviews: subviews, cache: &cache)
        let plan = makePlan(proposedWidth: proposal.width, cache: cache, subviews: subviews)
        let width = proposal.width ?? plan.idealWidth
        return CGSize(width: width, height: plan.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        measureIntrinsics(subviews: subviews, cache: &cache)
        let plan = makePlan(proposedWidth: bounds.width, cache: cache, subviews: subviews)

        for placement in plan.placements {
            guard let subview = subview(for: placement.role, in: subviews) else { continue }
            let originX = mirroredX(
                ltrOriginX: placement.origin.x,
                sizeWidth: placement.size.width,
                boundsWidth: bounds.width
            )
            subview.place(
                at: CGPoint(
                    x: bounds.minX + originX,
                    y: bounds.minY + placement.origin.y
                ),
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    /// Optional left-origin flip for DEBUG previews that stay in LTR environment.
    private func mirroredX(ltrOriginX: CGFloat, sizeWidth: CGFloat, boundsWidth: CGFloat) -> CGFloat {
        guard mirrorsHorizontally else { return ltrOriginX }
        return boundsWidth - ltrOriginX - sizeWidth
    }

    // MARK: - Measurement

    private func measureIntrinsics(subviews: Subviews, cache: inout Cache) {
        if let checkbox = subview(for: .checkbox, in: subviews) {
            cache.hasCheckbox = true
            cache.checkboxSize = checkbox.sizeThatFits(.unspecified)
        } else {
            cache.hasCheckbox = false
            cache.checkboxSize = .zero
        }

        if let thumbnail = subview(for: .thumbnail, in: subviews) {
            cache.hasThumbnail = true
            cache.thumbnailSize = thumbnail.sizeThatFits(.unspecified)
        } else {
            cache.hasThumbnail = false
            cache.thumbnailSize = .zero
        }

        if let title = subview(for: .title, in: subviews) {
            cache.hasTitle = true
            // Title-only ideal width drives protectedTitleWidth / Candidate A floor.
            cache.titleIdealSize = title.sizeThatFits(.unspecified)
        } else {
            cache.hasTitle = false
            cache.titleIdealSize = .zero
        }

        if subview(for: .metadata, in: subviews) != nil {
            cache.hasMetadata = true
            // Do NOT probe sizeThatFits(width: 0) on ViewThatFits metadata — it often
            // returns the wide ideal ("Produce · Walmart") instead of the compact pill,
            // which dishonestly demotes Candidate A. Metadata may grow height when
            // measured later at the assigned title-region width (see measureTitleRegion).
        } else {
            cache.hasMetadata = false
        }

        if let stepper = subview(for: .stepper, in: subviews) {
            cache.hasStepper = true
            cache.stepperSize = stepper.sizeThatFits(.unspecified)
        } else {
            cache.hasStepper = false
            cache.stepperSize = .zero
        }

        if let edit = subview(for: .edit, in: subviews) {
            cache.hasEdit = true
            cache.editSize = edit.sizeThatFits(.unspecified)
        } else {
            cache.hasEdit = false
            cache.editSize = .zero
        }
    }

    private func subview(for role: ItemRowLayoutRole, in subviews: Subviews) -> LayoutSubview? {
        subviews.first { $0[ItemRowLayoutRoleKey.self] == role }
    }

    // MARK: - Planning

    private struct Placement {
        var role: ItemRowLayoutRole
        var origin: CGPoint
        var size: CGSize
    }

    private struct Plan {
        var candidate: ItemRowCandidate
        var height: CGFloat
        var idealWidth: CGFloat
        var placements: [Placement]
    }

    private struct TitleRegionMeasure {
        var titleSize: CGSize
        var metadataSize: CGSize
        var height: CGFloat
    }

    private func makePlan(
        proposedWidth: CGFloat?,
        cache: Cache,
        subviews: Subviews
    ) -> Plan {
        let checkboxWidth = cache.hasCheckbox ? cache.checkboxSize.width : 0
        let thumbnailWidth = cache.hasThumbnail ? cache.thumbnailSize.width : 0
        let stepperWidth = cache.hasStepper ? cache.stepperSize.width : 0
        let editWidth = cache.hasEdit ? cache.editSize.width : 0

        // One-line floor from product title only — metadata width must not inflate this.
        let protected = ItemRowFitGeometry.protectedTitleWidth(
            oneLineIdealWidth: cache.titleIdealSize.width,
            baselineFloor: baselineTitleFloor,
            maximumInlineAllowance: maximumInlineTitleAllowance
        )

        let inlineRequired = ItemRowFitGeometry.inlineRequiredWidth(
            checkboxWidth: checkboxWidth,
            thumbnailWidth: thumbnailWidth,
            protectedTitleWidth: protected,
            stepperWidth: stepperWidth,
            editWidth: editWidth,
            spacing: spacing
        )

        let width = proposedWidth ?? inlineRequired

        // Title-region floor is title-only. Wide ViewThatFits metadata ideals are not a
        // trustworthy unbreakable minimum, so they must not raise this floor or demote A.
        // Metadata compacts/wraps inside the title column via measureTitleRegion.
        let titleSlotFloor = protected

        let splitRequired = ItemRowFitGeometry.splitRequiredWidth(
            checkboxWidth: checkboxWidth,
            thumbnailWidth: thumbnailWidth,
            protectedTitleWidth: titleSlotFloor,
            editWidth: editWidth,
            spacing: spacing
        )

        let candidate = ItemRowFitGeometry.selectCandidate(
            proposedWidth: width,
            inlineRequiredWidth: inlineRequired,
            splitRequiredWidth: splitRequired
        )

        #if DEBUG
        ItemRowCandidateDebug.lastSelected = candidate
        #endif

        switch candidate {
        case .inline:
            return planInline(
                width: width,
                titleSlotFloor: titleSlotFloor,
                cache: cache,
                subviews: subviews,
                idealWidth: inlineRequired
            )
        case .splitStepper:
            return planSplitStepper(
                width: width,
                titleSlotFloor: titleSlotFloor,
                cache: cache,
                subviews: subviews,
                idealWidth: inlineRequired
            )
        case .stackedControls:
            return planStackedControls(
                width: width,
                titleSlotFloor: titleSlotFloor,
                cache: cache,
                subviews: subviews,
                idealWidth: inlineRequired
            )
        }
    }

    private func titleLeadingX(cache: Cache) -> CGFloat {
        var x: CGFloat = 0
        if cache.hasCheckbox {
            x += cache.checkboxSize.width
        }
        if cache.hasThumbnail {
            if x > 0 { x += spacing }
            x += cache.thumbnailSize.width
        }
        if x > 0 { x += spacing }
        return x
    }

    /// Measures title + metadata as a vertical stack under the title region's width.
    private func measureTitleRegion(
        width: CGFloat,
        cache: Cache,
        subviews: Subviews
    ) -> TitleRegionMeasure {
        let titleHeight: CGFloat
        if let title = subview(for: .title, in: subviews) {
            titleHeight = title.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        } else {
            titleHeight = cache.titleIdealSize.height
        }

        var metadataSize = CGSize.zero
        if cache.hasMetadata, let metadata = subview(for: .metadata, in: subviews) {
            metadataSize = metadata.sizeThatFits(ProposedViewSize(width: width, height: nil))
        }

        let stackHeight: CGFloat
        if cache.hasMetadata && metadataSize.height > 0 {
            stackHeight = titleHeight + titleMetadataSpacing + metadataSize.height
        } else {
            stackHeight = titleHeight
        }

        return TitleRegionMeasure(
            titleSize: CGSize(width: width, height: titleHeight),
            metadataSize: CGSize(width: width, height: metadataSize.height),
            height: stackHeight
        )
    }

    private func appendTitleRegionPlacements(
        to placements: inout [Placement],
        origin: CGPoint,
        region: TitleRegionMeasure,
        cache: Cache
    ) {
        if cache.hasTitle {
            placements.append(
                Placement(
                    role: .title,
                    origin: origin,
                    size: region.titleSize
                )
            )
        }
        if cache.hasMetadata, region.metadataSize.height > 0 {
            placements.append(
                Placement(
                    role: .metadata,
                    origin: CGPoint(
                        x: origin.x,
                        y: origin.y + region.titleSize.height + titleMetadataSpacing
                    ),
                    size: region.metadataSize
                )
            )
        }
    }

    // MARK: - Candidate A

    private func planInline(
        width: CGFloat,
        titleSlotFloor: CGFloat,
        cache: Cache,
        subviews: Subviews,
        idealWidth: CGFloat
    ) -> Plan {
        let titleLeading = titleLeadingX(cache: cache)
        var trailingChrome: CGFloat = 0
        var trailingSlots = 0
        if cache.hasStepper {
            trailingChrome += cache.stepperSize.width
            trailingSlots += 1
        }
        if cache.hasEdit {
            trailingChrome += cache.editSize.width
            trailingSlots += 1
        }
        let trailingGaps = CGFloat(trailingSlots)
        let titleWidth = max(
            titleSlotFloor,
            width - titleLeading - trailingChrome - spacing * trailingGaps
        )
        let region = measureTitleRegion(width: titleWidth, cache: cache, subviews: subviews)

        let contentHeight = max(
            cache.hasCheckbox ? cache.checkboxSize.height : 0,
            cache.hasThumbnail ? cache.thumbnailSize.height : 0,
            region.height,
            cache.hasStepper ? cache.stepperSize.height : 0,
            cache.hasEdit ? cache.editSize.height : 0
        )
        let height = max(candidateAMinHeight, contentHeight)

        var placements: [Placement] = []
        var x: CGFloat = 0

        func append(_ role: ItemRowLayoutRole, size: CGSize, present: Bool) {
            guard present else { return }
            let y = (height - size.height) / 2
            placements.append(Placement(role: role, origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
        }

        append(.checkbox, size: cache.checkboxSize, present: cache.hasCheckbox)
        append(.thumbnail, size: cache.thumbnailSize, present: cache.hasThumbnail)

        if cache.hasTitle || cache.hasMetadata {
            let y = (height - region.height) / 2
            appendTitleRegionPlacements(
                to: &placements,
                origin: CGPoint(x: x, y: y),
                region: region,
                cache: cache
            )
            x += titleWidth + spacing
        }

        append(.stepper, size: cache.stepperSize, present: cache.hasStepper)
        append(.edit, size: cache.editSize, present: cache.hasEdit)

        return Plan(
            candidate: .inline,
            height: height,
            idealWidth: idealWidth,
            placements: placements
        )
    }

    // MARK: - Candidate B
    //
    // Primary:   checkbox | thumbnail | title                    | edit
    // Secondary:                        category / store   | stepper
    //
    // Stepper sits on the metadata line (trailing), never on an isolated full-width third row.

    private func planSplitStepper(
        width: CGFloat,
        titleSlotFloor: CGFloat,
        cache: Cache,
        subviews: Subviews,
        idealWidth: CGFloat
    ) -> Plan {
        let titleLeading = titleLeadingX(cache: cache)
        let editWidth = cache.hasEdit ? cache.editSize.width : 0
        let editGap = cache.hasEdit ? spacing : 0
        let titleColumnWidth = max(titleSlotFloor, width - titleLeading - editWidth - editGap)

        let titleHeight: CGFloat
        if let title = subview(for: .title, in: subviews) {
            titleHeight = title.sizeThatFits(
                ProposedViewSize(width: titleColumnWidth, height: nil)
            ).height
        } else {
            titleHeight = cache.titleIdealSize.height
        }

        let stepperWidth = cache.hasStepper ? cache.stepperSize.width : 0
        let stepperGap = (cache.hasStepper && cache.hasMetadata) ? spacing : 0
        let metadataMaxWidth: CGFloat
        if cache.hasMetadata {
            metadataMaxWidth = max(0, titleColumnWidth - stepperWidth - stepperGap)
        } else {
            metadataMaxWidth = 0
        }

        var metadataSize = CGSize.zero
        if cache.hasMetadata, let metadata = subview(for: .metadata, in: subviews) {
            metadataSize = metadata.sizeThatFits(
                ProposedViewSize(width: metadataMaxWidth, height: nil)
            )
        }

        let secondaryHeight = max(
            metadataSize.height,
            cache.hasStepper ? cache.stepperSize.height : 0
        )
        let hasSecondary = secondaryHeight > 0
        let textBlockHeight = titleHeight
            + (hasSecondary ? titleMetadataSpacing + secondaryHeight : 0)

        let contentHeight = max(
            cache.hasCheckbox ? cache.checkboxSize.height : 0,
            cache.hasThumbnail ? cache.thumbnailSize.height : 0,
            textBlockHeight,
            cache.hasEdit ? cache.editSize.height : 0
        )
        let height = max(candidateBMinHeight, contentHeight)

        let topAlign = textBlockHeight > max(
            cache.checkboxSize.height,
            cache.thumbnailSize.height
        )

        var placements: [Placement] = []
        var x: CGFloat = 0

        func appendLeading(_ role: ItemRowLayoutRole, size: CGSize, present: Bool) {
            guard present else { return }
            let y = topAlign ? 0 : (height - size.height) / 2
            placements.append(Placement(role: role, origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
        }

        appendLeading(.checkbox, size: cache.checkboxSize, present: cache.hasCheckbox)
        appendLeading(.thumbnail, size: cache.thumbnailSize, present: cache.hasThumbnail)

        let textOriginY = topAlign ? 0 : (height - textBlockHeight) / 2

        if cache.hasTitle {
            placements.append(
                Placement(
                    role: .title,
                    origin: CGPoint(x: titleLeading, y: textOriginY),
                    size: CGSize(width: titleColumnWidth, height: titleHeight)
                )
            )
        }

        if cache.hasEdit {
            let editX = width - cache.editSize.width
            // Keep edit on the title line (not vertically centered on the whole block).
            let editY = textOriginY + max(0, (titleHeight - cache.editSize.height) / 2)
            placements.append(
                Placement(
                    role: .edit,
                    origin: CGPoint(x: editX, y: editY),
                    size: cache.editSize
                )
            )
        }

        if hasSecondary {
            let secondaryY = textOriginY + titleHeight + titleMetadataSpacing

            if cache.hasMetadata, metadataSize.height > 0 {
                let metaY = secondaryY + max(0, (secondaryHeight - metadataSize.height) / 2)
                placements.append(
                    Placement(
                        role: .metadata,
                        origin: CGPoint(x: titleLeading, y: metaY),
                        size: CGSize(width: metadataMaxWidth, height: metadataSize.height)
                    )
                )
            }

            if cache.hasStepper {
                let stepperX = titleLeading + titleColumnWidth - cache.stepperSize.width
                let stepperY = secondaryY + max(
                    0,
                    (secondaryHeight - cache.stepperSize.height) / 2
                )
                placements.append(
                    Placement(
                        role: .stepper,
                        origin: CGPoint(x: stepperX, y: stepperY),
                        size: cache.stepperSize
                    )
                )
            }
        }

        return Plan(
            candidate: .splitStepper,
            height: height,
            idealWidth: idealWidth,
            placements: placements
        )
    }

    // MARK: - Candidate C

    private func planStackedControls(
        width: CGFloat,
        titleSlotFloor: CGFloat,
        cache: Cache,
        subviews: Subviews,
        idealWidth: CGFloat
    ) -> Plan {
        let titleLeading = titleLeadingX(cache: cache)
        let titleWidth = max(titleSlotFloor, width - titleLeading)
        let region = measureTitleRegion(width: titleWidth, cache: cache, subviews: subviews)

        let topRowHeight = max(
            cache.hasCheckbox ? cache.checkboxSize.height : 0,
            cache.hasThumbnail ? cache.thumbnailSize.height : 0,
            region.height
        )

        var bottomRowHeight: CGFloat = 0
        if cache.hasStepper {
            bottomRowHeight = max(bottomRowHeight, cache.stepperSize.height)
        }
        if cache.hasEdit {
            bottomRowHeight = max(bottomRowHeight, cache.editSize.height)
        }

        let hasBottomRow = cache.hasStepper || cache.hasEdit
        let contentHeight = topRowHeight + (hasBottomRow ? spacing + bottomRowHeight : 0)
        // Do not reserve stacked control-row minimum when no bottom chrome is present.
        let minHeight = hasBottomRow ? candidateCMinHeight : candidateAMinHeight
        let height = max(minHeight, contentHeight)

        var placements: [Placement] = []
        var x: CGFloat = 0

        // Always top-align checkbox/thumbnail against tall title blocks in C.
        func appendTop(_ role: ItemRowLayoutRole, size: CGSize, present: Bool) {
            guard present else { return }
            placements.append(Placement(role: role, origin: CGPoint(x: x, y: 0), size: size))
            x += size.width + spacing
        }

        appendTop(.checkbox, size: cache.checkboxSize, present: cache.hasCheckbox)
        appendTop(.thumbnail, size: cache.thumbnailSize, present: cache.hasThumbnail)

        if cache.hasTitle || cache.hasMetadata {
            appendTitleRegionPlacements(
                to: &placements,
                origin: CGPoint(x: x, y: 0),
                region: region,
                cache: cache
            )
        }

        var bottomX = titleLeading
        let bottomY = topRowHeight + spacing

        if cache.hasStepper {
            placements.append(
                Placement(
                    role: .stepper,
                    origin: CGPoint(x: bottomX, y: bottomY),
                    size: cache.stepperSize
                )
            )
            bottomX += cache.stepperSize.width + spacing
        }

        if cache.hasEdit {
            placements.append(
                Placement(
                    role: .edit,
                    origin: CGPoint(x: bottomX, y: bottomY),
                    size: cache.editSize
                )
            )
        }

        return Plan(
            candidate: .stackedControls,
            height: height,
            idealWidth: idealWidth,
            placements: placements
        )
    }
}
