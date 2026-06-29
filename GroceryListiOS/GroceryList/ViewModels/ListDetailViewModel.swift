import Foundation
import SwiftData

@Observable
@MainActor
final class ListDetailViewModel {
    var draftText = ""
    var undoSnapshot: DeletedItemSnapshot?
    var toastMessage: String?
    var editingItem: GroceryItem?
    var isPickedUpExpanded = true
    var showCompletedItems = true
    var isSelectionMode = false
    var isReorderMode = false
    var selectedItemIds: Set<UUID> = []
    var showAssignSheet = false

    private var undoDismissTask: Task<Void, Never>?

    func addItem(to list: GroceryList, context: ModelContext) {
        guard !GroceryItemService.addItems(name: draftText, to: list, context: context).isEmpty else { return }
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

    func saveEdit(for item: GroceryItem, draft: ItemEditDraft, context: ModelContext) {
        guard showSaveFailureIfNeeded(GroceryItemService.updateItem(item, draft: draft, context: context)) else { return }
        editingItem = nil
    }

    func deleteFromEdit(_ item: GroceryItem, context: ModelContext) {
        let snapshot = GroceryItemService.deleteItem(item, context: context)
        editingItem = nil
        scheduleUndo(snapshot: snapshot, message: "Deleted \"\(snapshot.name)\"")
        HapticsService.delete()
    }

    func clearCompleted(in list: GroceryList, context: ModelContext) {
        guard showSaveFailureIfNeeded(GroceryItemService.clearCompleted(in: list, context: context)) else { return }
        HapticsService.selection()
    }

    func duplicateItem(_ item: GroceryItem, in list: GroceryList, context: ModelContext) {
        guard showSaveFailureIfNeeded(GroceryItemService.duplicateItem(item, in: list, context: context)) else { return }
        HapticsService.add()
    }

    func duplicateFromEdit(_ item: GroceryItem, in list: GroceryList, context: ModelContext) {
        guard showSaveFailureIfNeeded(GroceryItemService.duplicateItem(item, in: list, context: context)) else { return }
        editingItem = nil
        showInfoToast("Duplicated \(item.name)")
        HapticsService.add()
    }

    func showInfoToast(_ message: String) {
        cancelUndoTimer()
        undoSnapshot = nil
        toastMessage = message
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }

    func updateCategory(_ item: GroceryItem, categoryId: String, context: ModelContext) {
        guard showSaveFailureIfNeeded(GroceryItemService.updateCategory(item, categoryId: categoryId, context: context)) else { return }
        HapticsService.selection()
    }

    func updateStore(_ item: GroceryItem, storeId: String?, context: ModelContext) {
        guard showSaveFailureIfNeeded(GroceryItemService.updateStore(item, storeId: storeId, context: context)) else { return }
        HapticsService.selection()
    }

    func moveActiveItems(in list: GroceryList, from source: IndexSet, to destination: Int, context: ModelContext) {
        showSaveFailureIfNeeded(
            GroceryItemService.moveItems(in: list, from: source, to: destination, activeOnly: true, context: context)
        )
    }

    func toggleSelection(for item: GroceryItem) {
        if selectedItemIds.contains(item.id) {
            selectedItemIds.remove(item.id)
        } else {
            selectedItemIds.insert(item.id)
        }
        HapticsService.selection()
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedItemIds.removeAll()
    }

    func enterSelectionMode() {
        exitReorderMode()
        isSelectionMode = true
    }

    func exitReorderMode() {
        isReorderMode = false
    }

    func enterReorderMode() {
        exitSelectionMode()
        isReorderMode = true
    }

    func selectedItems(in list: GroceryList) -> [GroceryItem] {
        list.items.filter { selectedItemIds.contains($0.id) && !$0.isArchived }
    }

    func deleteSelected(in list: GroceryList, context: ModelContext) {
        let items = selectedItems(in: list)
        guard let last = items.last else { return }
        for item in items.dropLast() {
            _ = GroceryItemService.deleteItem(item, context: context)
        }
        let snapshot = GroceryItemService.deleteItem(last, context: context)
        exitSelectionMode()
        scheduleUndo(snapshot: snapshot, message: "Deleted \(items.count) item\(items.count == 1 ? "" : "s")")
        HapticsService.delete()
    }

    func assignSelected(to target: GroceryList, from list: GroceryList, context: ModelContext) {
        let items = selectedItems(in: list)
        guard showSaveFailureIfNeeded(GroceryItemService.assignItems(items, to: target, context: context)) else { return }
        exitSelectionMode()
        HapticsService.selection()
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
        showInfoToast("Couldn't save. Please try again.")
        return false
    }
}
