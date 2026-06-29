import SwiftUI

struct EmptyStateScene<Illustration: View>: View {
    let title: String
    let message: String
    @ViewBuilder let illustration: () -> Illustration
    var primaryTitle: String?
    var primaryAction: (() -> Void)?
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?
    var starterChips: [String] = []
    var onStarterChip: ((String) -> Void)?
    var expandVertically: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            if expandVertically { Spacer(minLength: 24) }

            illustration()
                .padding(.bottom, 4)

            VStack(spacing: 8) {
                Text(title)
                    .font(AppTypography.emptyStateTitle)
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if !starterChips.isEmpty, let onStarterChip {
                VStack(spacing: 10) {
                    Text("Try adding")
                        .appSectionLabel()
                    EmptyStateFlowLayout(spacing: 8) {
                        ForEach(starterChips, id: \.self) { chip in
                            StarterChip(title: chip) {
                                HapticsService.selection()
                                onStarterChip(chip)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            if primaryTitle != nil || secondaryTitle != nil {
                VStack(spacing: 10) {
                    if let primaryTitle, let primaryAction {
                        Button(primaryTitle, action: primaryAction)
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    if let secondaryTitle, let secondaryAction {
                        Button(secondaryTitle, action: secondaryAction)
                            .font(AppTypography.button)
                            .foregroundStyle(AppColors.ink)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 4)
            }

            if expandVertically { Spacer(minLength: 24) }
        }
        .frame(maxWidth: .infinity, maxHeight: expandVertically ? .infinity : nil)
        .padding(.vertical, expandVertically ? 0 : 24)
    }
}

struct EmptyStateFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions, sizes)
    }
}
