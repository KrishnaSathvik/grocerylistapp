import SwiftData
import SwiftUI
import UIKit

/// Plain-text share payload for Messages — list items only, no link preview cards.
final class GroceryListShareItemSource: NSObject, UIActivityItemSource {
    let listName: String
    let bodyText: String

    init(list: GroceryList, context: ModelContext) {
        listName = list.name
        bodyText = ShareTextFormatter.formatForMessages(list: list, context: context)
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        bodyText
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        bodyText
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        listName
    }
}

enum GroceryListShareBuilder {
    static func activityItems(for list: GroceryList, context: ModelContext) -> [Any] {
        [GroceryListShareItemSource(list: list, context: context)]
    }

    static func copyText(for list: GroceryList, context: ModelContext) -> String {
        ShareTextFormatter.formatPlainList(list: list, context: context)
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
