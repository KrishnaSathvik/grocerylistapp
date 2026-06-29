import SwiftUI
import SwiftData

struct AssignToListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    let currentListId: UUID
    let onAssign: (GroceryList) -> Void

    @State private var searchText = ""
    @State private var isCreatingList = false

    private var filteredLists: [GroceryList] {
        let others = lists.filter { $0.id != currentListId }
        guard !searchText.isEmpty else { return others }
        return others.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredLists) { list in
                    Button {
                        onAssign(list)
                        dismiss()
                    } label: {
                        HStack {
                            ListCardView(list: list)
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .adaptiveContentWidth(alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .searchable(text: $searchText, prompt: "Search lists")
            .navigationTitle("Assign to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isCreatingList = true
                    } label: {
                        Image(systemName: AppIcons.add)
                    }
                }
            }
            .sheet(isPresented: $isCreatingList) {
                EditListSheet(mode: .create) { name, description, icon, tint in
                    if let list = GroceryListService.createList(
                        name: name,
                        description: description,
                        iconName: icon,
                        tintHex: tint,
                        context: modelContext
                    ) {
                        onAssign(list)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
