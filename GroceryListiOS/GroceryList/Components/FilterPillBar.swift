import SwiftUI

struct FilterPillBar: View {
    @Binding var selection: ListFilterMode

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ListFilterMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(AppTypography.button)
                        .foregroundStyle(selection == mode ? AppColors.accentCTAForeground : AppColors.ink)
                        .padding(.horizontal, 16)
                        .frame(minHeight: AppSpacing.minTapTarget)
                        .background(selection == mode ? AppColors.accentCTA : AppColors.filterUnselected)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.rawValue)
                .accessibilityAddTraits(selection == mode ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }
}
