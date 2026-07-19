import SwiftUI

struct QuantityStepper: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let value: Int
    var isMuted: Bool = false
    var onDecrement: () -> Void
    var onIncrement: () -> Void

    /// Layout / reported size — matches `ItemRowFitGeometry.Chrome.stepperWidth`.
    /// Visual capsule is shorter than the 44×44 tap targets; buttons may paint slightly
    /// outside the reported height so Candidate B’s metadata line stays compact.
    private static let layoutWidth: CGFloat = ItemRowFitGeometry.Chrome.stepperWidth
    private static let capsuleHeight: CGFloat = ItemRowFitGeometry.Chrome.stepperVisualHeight

    private var glyphColor: Color {
        isMuted ? AppColors.completedInk.opacity(0.85) : AppColors.inkSecondary.opacity(0.85)
    }

    private var buttonGlyphColor: Color {
        isMuted ? AppColors.completedInk.opacity(0.7) : AppColors.inkSecondary.opacity(0.7)
    }

    private var usesAccessibilityLayout: Bool {
        DynamicTypeLayout.usesAccessibilityLayout(dynamicTypeSize)
    }

    private var capsuleFill: Color {
        isMuted
            ? AppColors.completedRowBackground
            : AppColors.filterUnselected.opacity(0.4)
    }

    var body: some View {
        ZStack {
            Capsule()
                .fill(capsuleFill)
                .frame(width: Self.layoutWidth, height: Self.capsuleHeight)
                .overlay(
                    Capsule().stroke(
                        AppColors.cardBorder.opacity(isMuted ? 0.25 : 0.35),
                        lineWidth: 0.5
                    )
                )

            Text("\(value)")
                .font(
                    usesAccessibilityLayout
                        ? AppTypography.caption.weight(.semibold)
                        : .system(size: 12, weight: .semibold, design: .rounded)
                )
                .foregroundStyle(glyphColor)
                .accessibilityHidden(true)

            // Keep − left / + right regardless of row RTL mirroring so meanings stay obvious.
            HStack(spacing: 0) {
                stepperButton(
                    systemName: "minus",
                    label: "Decrease quantity",
                    glyphAlignment: .leading,
                    action: onDecrement
                )
                stepperButton(
                    systemName: "plus",
                    label: "Increase quantity",
                    glyphAlignment: .trailing,
                    action: onIncrement
                )
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        // Reported layout size uses the compact capsule height; 44×44 buttons remain
        // inside and may extend slightly beyond this frame for hit testing.
        .frame(width: Self.layoutWidth, height: Self.capsuleHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quantity")
        .accessibilityValue("\(value)")
    }

    @ViewBuilder
    private func stepperButton(
        systemName: String,
        label: String,
        glyphAlignment: Alignment,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(buttonGlyphColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: glyphAlignment)
                .padding(.horizontal, 10)
        }
        .buttonStyle(.plain)
        .frame(width: AppSpacing.minTapTarget, height: AppSpacing.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityLabel(label)
    }
}

#Preview {
    QuantityStepper(value: 2, onDecrement: {}, onIncrement: {})
}
