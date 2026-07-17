import SwiftUI
import SwiftData
import UIKit

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var allLists: [GroceryList]

    @Bindable var list: GroceryList
    @Bindable var viewModel: ListDetailViewModel
    var onSwitchList: ((UUID) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isQuickAddFocused: Bool
    @State private var showShareSheet = false
    @State private var showSelectedShareSheet = false
    @State private var selectedShareText = ""
    @State private var showAddItem = false
    @State private var addItemPrefill = ""
    @State private var showRenameSheet = false
    @State private var showClearCompletedAlert = false
    @State private var showDeleteListAlert = false

    init(list: GroceryList, viewModel: ListDetailViewModel, onSwitchList: ((UUID) -> Void)? = nil) {
        self.list = list
        self.viewModel = viewModel
        self.onSwitchList = onSwitchList
    }

    init(list: GroceryList, onSwitchList: ((UUID) -> Void)? = nil) {
        self.init(list: list, viewModel: ListDetailViewModel(), onSwitchList: onSwitchList)
    }

    var body: some View {
        AdaptiveScreenShell {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    ListDetailHeader(
                        listName: list.name,
                        lists: allLists,
                        canClearCompleted: !completedItems.isEmpty,
                        showCompletedItems: viewModel.showCompletedItems,
                        onBack: { dismiss() },
                        onSelectList: switchToList,
                        onShareList: { showShareSheet = true },
                        onRenameList: { showRenameSheet = true },
                        onToggleCompletedVisibility: {
                            viewModel.showCompletedItems.toggle()
                            HapticsService.selection()
                        },
                        onClearCompleted: { showClearCompletedAlert = true },
                        onDeleteList: { showDeleteListAlert = true }
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        QuickAddBar(text: $viewModel.draftText, focus: $isQuickAddFocused, onSubmit: {
                            viewModel.addItem(to: list, context: modelContext)
                        })

                        if isQuickAddFocused && viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            QuickAddHelperText()
                                .padding(.leading, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        AddItemDetectionPreview(text: viewModel.draftText, modelContext: modelContext)
                            .padding(.leading, 4)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.draftText)
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isQuickAddFocused)
                }
                .adaptiveHorizontalPadding()
                .padding(.top, 8)
                .padding(.bottom, 12)

                if isListEmpty {
                    ImageEmptyStateHero(
                        imageName: "empty_list_illustration",
                        fallbackSystemImage: "checklist",
                        title: "Your list is empty",
                        subtitle: "Add your first item above and we'll keep everything organized for shopping."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        AllItemsListContent(
                            list: list,
                            viewModel: viewModel,
                            modelContext: modelContext
                        )
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        } bottomOverlay: {
            Group {
                if viewModel.isSelectionMode, !viewModel.selectedItemIds.isEmpty {
                    SelectionToolbar(
                        selectedCount: viewModel.selectedItemIds.count,
                        onAssign: { viewModel.showAssignSheet = true },
                        onShare: shareSelected,
                        onCopy: copySelected,
                        onDelete: { viewModel.deleteSelected(in: list, context: modelContext) }
                    )
                    .padding(.bottom, 12)
                    .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
                } else if let message = viewModel.toastMessage {
                    if viewModel.undoSnapshot != nil {
                        UndoBanner(message: message) {
                            viewModel.undoDelete(in: list, context: modelContext)
                        }
                        .padding(.bottom, 16)
                        .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
                    } else {
                        ToastBanner(message: message)
                            .padding(.bottom, 16)
                            .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.toastMessage)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.isSelectionMode)
        .onAppear {
            ActiveListResolver.setActive(list)
            GroceryItemService.reconcileImageAssets(in: list, context: modelContext)
        }
        .toolbar(.hidden, for: .navigationBar)
        .adaptiveSheet(isPresented: $showShareSheet) {
            ShareListSheet(list: list)
        }
        .adaptiveSheet(isPresented: $showRenameSheet) {
            EditListSheet(mode: .edit(list)) { name, description, icon, tint in
                GroceryListService.updateList(
                    list,
                    name: name,
                    description: description,
                    iconName: icon,
                    tintHex: tint,
                    context: modelContext
                )
            }
        }
        .fullScreenCover(item: $viewModel.editingItem) { item in
            EditItemSheet(
                item: item,
                lists: allLists,
                onSave: { draft in
                    viewModel.saveEdit(for: item, draft: draft, context: modelContext)
                },
                onDuplicate: {
                    viewModel.duplicateFromEdit(item, in: list, context: modelContext)
                },
                onDelete: {
                    viewModel.deleteFromEdit(item, context: modelContext)
                }
            )
        }
        .adaptiveSheet(isPresented: $viewModel.showAssignSheet) {
            AssignToListSheet(currentListId: list.id) { target in
                viewModel.assignSelected(to: target, from: list, context: modelContext)
            }
        }
        .sheet(isPresented: $showSelectedShareSheet) {
            ActivityShareSheet(items: [selectedShareText]) {
                viewModel.exitSelectionMode()
            }
        }
        .adaptiveSheet(isPresented: $showAddItem) {
            AddItemSheet(list: list, initialText: addItemPrefill)
        }
        .onChange(of: showAddItem) { _, isShowing in
            if !isShowing { addItemPrefill = "" }
        }
        .alert("Clear Completed Items?", isPresented: $showClearCompletedAlert) {
            Button("Clear", role: .destructive) {
                viewModel.clearCompleted(in: list, context: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes completed items from \"\(list.name)\".")
        }
        .alert("Delete List?", isPresented: $showDeleteListAlert) {
            Button("Delete", role: .destructive) {
                deleteList()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(list.name)\" and all its items.")
        }
    }

    private var activeItems: [GroceryItem] {
        list.items.filter { !$0.isCompleted && !$0.isArchived }
    }

    private var completedItems: [GroceryItem] {
        list.items.filter { $0.isCompleted && !$0.isArchived }
    }

    private var isListEmpty: Bool {
        list.items.filter { !$0.isArchived }.isEmpty
    }

    private func switchToList(_ target: GroceryList) {
        guard target.id != list.id else { return }
        ActiveListResolver.setActive(target)
        onSwitchList?(target.id)
    }

    private func deleteList() {
        _ = GroceryListService.deleteList(list, context: modelContext)
        HapticsService.selection()
        dismiss()
    }

    private func shareSelected() {
        let items = viewModel.selectedItems(in: list)
        selectedShareText = ShareTextFormatter.formatSelectedItems(items, listName: list.name)
        showSelectedShareSheet = true
    }

    private func copySelected() {
        let items = viewModel.selectedItems(in: list)
        UIPasteboard.general.string = ShareTextFormatter.formatSelectedItems(items, listName: list.name)
        viewModel.toastMessage = "Copied!"
        HapticsService.selection()
    }
}

#Preview {
    NavigationStack {
        ListDetailView(list: GroceryList(name: "Weekly Groceries"))
    }
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
