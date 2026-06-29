import Foundation
import SwiftData

@Observable
@MainActor
final class FocusedShoppingViewModel {
    var draftText = ""
    var undoSnapshot: DeletedItemSnapshot?
    var toastMessage: String?
    var showCompletedItems = true
    var isPickedUpExpanded = true

    private var undoDismissTask: Task<Void, Never>?

    func addItem(
        to list: GroceryList,
        context: ModelContext,
        prefilledStoreId: String?,
        prefilledCategoryId: String?
    ) {
        guard !GroceryItemService.addItems(
            name: draftText,
            to: list,
            context: context,
            prefilledStoreId: prefilledStoreId,
            prefilledCategoryId: prefilledCategoryId
        ).isEmpty else { return }
        draftText = ""
        HapticsService.add()
    }

    func toggleComplete(_ item: GroceryItem, context: ModelContext) {
        guard showSaveFailureIfNeeded(GroceryItemService.toggleComplete(item, context: context)) else { return }
        HapticsService.check()
    }

    func incrementQuantity(_ item: GroceryItem, context: ModelContext) {
        let current = max(item.quantityValue ?? 1, 1)
        guard showSaveFailureIfNeeded(
            GroceryItemService.updateQuantity(item, value: min(current + 1, 99), context: context)
        ) else { return }
        HapticsService.stepper()
    }

    func decrementQuantity(_ item: GroceryItem, context: ModelContext) {
        let current = max(item.quantityValue ?? 1, 1)
        let saved: Bool
        if current <= 1 {
            saved = GroceryItemService.updateQuantity(item, value: nil, context: context)
        } else {
            saved = GroceryItemService.updateQuantity(item, value: current - 1, context: context)
        }
        guard showSaveFailureIfNeeded(saved) else { return }
        HapticsService.stepper()
    }

    func deleteItem(_ item: GroceryItem, context: ModelContext) {
        let snapshot = GroceryItemService.deleteItem(item, context: context)
        scheduleUndo(snapshot: snapshot, message: "Deleted \"\(snapshot.name)\"")
        HapticsService.delete()
    }

    func undoDelete(in list: GroceryList, context: ModelContext) {
        guard let snapshot = undoSnapshot else { return }
        cancelUndoTimer()
        guard showSaveFailureIfNeeded(GroceryItemService.restoreItem(snapshot, to: list, context: context)) else { return }
        undoSnapshot = nil
        toastMessage = nil
        HapticsService.undo()
    }

    private func scheduleUndo(snapshot: DeletedItemSnapshot, message: String) {
        cancelUndoTimer()
        undoSnapshot = snapshot
        toastMessage = message
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(3.5))
            guard !Task.isCancelled else { return }
            undoSnapshot = nil
            toastMessage = nil
        }
    }

    private func cancelUndoTimer() {
        undoDismissTask?.cancel()
        undoDismissTask = nil
    }

    @discardableResult
    private func showSaveFailureIfNeeded(_ saved: Bool) -> Bool {
        guard !saved else { return true }
        toastMessage = "Couldn't save. Please try again."
        undoSnapshot = nil
        cancelUndoTimer()
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
        return false
    }
}
