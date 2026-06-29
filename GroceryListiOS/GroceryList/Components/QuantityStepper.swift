import SwiftUI

struct QuantityStepper: View {
    let value: Int
    var onDecrement: () -> Void
    var onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            stepperButton(
                systemName: "minus",
                label: "Decrease quantity",
                action: onDecrement
            )
            Text("\(value)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.inkSecondary.opacity(0.85))
                .frame(minWidth: 18)
                .accessibilityHidden(true)
            stepperButton(
                systemName: "plus",
                label: "Increase quantity",
                action: onIncrement
            )
        }
        .padding(.horizontal, 2)
        .frame(width: 76, height: 26)
        .background(AppColors.filterUnselected.opacity(0.4))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(AppColors.cardBorder.opacity(0.35), lineWidth: 0.5)
        )
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
                .foregroundStyle(AppColors.inkSecondary.opacity(0.7))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minWidth: 32, minHeight: 32)
        .contentShape(Rectangle())
        .accessibilityLabel(label)
    }
}

#Preview {
    QuantityStepper(value: 2, onDecrement: {}, onIncrement: {})
}
