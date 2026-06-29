import SwiftUI
import SwiftData

struct AddItemDetectionPreview: View {
    let text: String
    let modelContext: ModelContext

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedItems: [ParsedItemInput] {
        let rules = CategoryLearningService.fetchRules(context: modelContext)
        let stores = StoreService.storeDefinitions(context: modelContext)
        return MultiItemInputParser.parse(trimmed, learningRules: rules, stores: stores)
    }

    private var preview: QuickAddPreviewContent? {
        QuickAddPreviewFormatter.preview(for: parsedItems, modelContext: modelContext)
    }

    var body: some View {
        if let preview {
            VStack(alignment: .leading, spacing: 4) {
                if let header = preview.header {
                    Text(header)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(1)
                }

                ForEach(Array(preview.lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(1)
                }

                if preview.moreCount > 0 {
                    Text("+\(preview.moreCount) more")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(preview.accessibilityLabel)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

struct QuickAddPreviewContent: Equatable {
    let header: String?
    let lines: [String]
    let moreCount: Int

    var accessibilityLabel: String {
        var parts: [String] = []
        if let header {
            parts.append(header)
        }
        parts.append(contentsOf: lines)
        if moreCount > 0 {
            parts.append("+\(moreCount) more")
        }
        return parts.joined(separator: ". ")
    }
}

enum QuickAddPreviewFormatter {
    static func preview(
        for items: [ParsedItemInput],
        modelContext: ModelContext
    ) -> QuickAddPreviewContent? {
        let confident = items.filter(\.hasConfidentPreview)
        guard !confident.isEmpty else { return nil }

        if confident.count == 1 {
            let line = itemLine(for: confident[0], modelContext: modelContext)
            return QuickAddPreviewContent(
                header: "Will add: \(line)",
                lines: [],
                moreCount: 0
            )
        }

        let maxVisible = 3
        let visible = Array(confident.prefix(maxVisible))
        let moreCount = max(confident.count - visible.count, 0)

        return QuickAddPreviewContent(
            header: "Will add \(confident.count) items:",
            lines: visible.map { itemLine(for: $0, modelContext: modelContext) },
            moreCount: moreCount
        )
    }

    static func line(for parsed: ParsedItemInput, modelContext: ModelContext) -> String? {
        guard parsed.hasConfidentPreview else { return nil }
        return "Will add: \(itemLine(for: parsed, modelContext: modelContext))"
    }

    private static func itemLine(for parsed: ParsedItemInput, modelContext: ModelContext) -> String {
        let itemLabel = parsed.name.capitalized
        let itemSegment: String
        if let quantity = quantityLabel(for: parsed) {
            itemSegment = "\(quantity) \(itemLabel)"
        } else {
            itemSegment = itemLabel
        }

        var segments = [itemSegment]

        if parsed.categoryId != "misc" {
            segments.append(CategoryService.label(for: parsed.categoryId))
        }

        if let storeId = parsed.storeId {
            let storeLabel = StoreService.label(for: storeId, context: modelContext)
            if storeLabel != "Unassigned" {
                segments.append(storeLabel)
            }
        } else if let customStoreLabel = parsed.customStoreLabel {
            segments.append(customStoreLabel)
        }

        return segments.joined(separator: " · ")
    }

    private static func quantityLabel(for parsed: ParsedItemInput) -> String? {
        if let text = parsed.quantityText, !text.isEmpty {
            return text
        }
        if let value = parsed.quantityValue {
            return "\(value)"
        }
        return nil
    }
}
