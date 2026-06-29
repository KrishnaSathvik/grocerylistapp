import SwiftUI

struct QuantityStepper: View {
    let value: Int
    var isMuted: Bool = false
    var onDecrement: () -> Void
    var onIncrement: () -> Void

    private var glyphColor: Color {
        isMuted ? AppColors.completedInk.opacity(0.85) : AppColors.inkSecondary.opacity(0.85)
    }

    private var buttonGlyphColor: Color {
        isMuted ? AppColors.completedInk.opacity(0.7) : AppColors.inkSecondary.opacity(0.7)
    }

    var body: some View {
        HStack(spacing: 0) {
            stepperButton(
                systemName: "minus",
                label: "Decrease quantity",
                action: onDecrement
            )
            Text("\(value)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(glyphColor)
                .frame(minWidth: 18)
                .accessibilityHidden(true)
            stepperButton(
                systemName: "plus",
                label: "Increase quantity",
                action: onIncrement
            )
        }
        .padding(.horizontal, 2)
        .frame(width: 88, height: 28)
        .background(
            isMuted
                ? AppColors.completedRowBackground
                : AppColors.filterUnselected.opacity(0.4)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(AppColors.cardBorder.opacity(isMuted ? 0.25 : 0.35), lineWidth: 0.5)
        )
        .frame(minHeight: AppSpacing.minTapTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quantity")
        .accessibilityValue("\(value)")
    }

    @ViewBuilder
    private func stepperButton(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(buttonGlyphColor)
                .frame(width: 24, height: 24)
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
