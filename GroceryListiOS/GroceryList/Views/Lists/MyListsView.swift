import SwiftUI
import SwiftData
import UIKit

struct MyListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    @State private var path = NavigationPath()
    @State private var sheetMode: ListSheetMode?
    #if DEBUG
    @State private var didAutoOpenProduceReview = false
    @State private var didAutoOpenFinalCatalogReview = false
    #endif

    enum ListSheetMode: Identifiable {
        case create
        case edit(GroceryList)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let list): return list.id.uuidString
            }
        }
    }

    private var activeListId: UUID? {
        ActiveListResolver.resolve(from: lists)?.id
    }

    private var activeList: GroceryList? {
        guard let activeListId else { return nil }
        return lists.first { $0.id == activeListId }
    }

    private var otherLists: [GroceryList] {
        guard let activeListId else { return lists }
        return lists.filter { $0.id != activeListId }
    }

    var body: some View {
        NavigationStack(path: $path) {
            TopLevelTabScreen(
                title: "My Lists",
                subtitle: "Plan each grocery run and keep everything organized."
            ) {
                ScrollView {
                    VStack(spacing: 0) {
                        if !lists.isEmpty {
                            PrimaryActionRow(
                                title: "New List",
                                systemImage: "plus.circle.fill"
                            ) {
                                sheetMode = .create
                            }
                            .adaptiveHorizontalPadding()
                        }

                        if lists.isEmpty {
                            MyListsEmptyState(onCreateList: { sheetMode = .create })
                                .adaptiveHorizontalPadding()
                                .padding(.top, AppSpacing.sectionSpacing)
                        } else {
                            LazyVStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                                if let activeList {
                                    Text("Active")
                                        .appSectionLabel()
                                        .adaptiveHorizontalPadding()
                                        .padding(.top, AppSpacing.sectionSpacing)

                                    listLink(for: activeList, isActive: true)
                                        .adaptiveHorizontalPadding()
                                }

                                if !otherLists.isEmpty {
                                    ForEach(otherLists) { list in
                                        listLink(for: list, isActive: false)
                                            .adaptiveHorizontalPadding()
                                    }
                                }
                            }
                        }

                        starterTemplatesSection
                            .padding(.top, lists.isEmpty ? 8 : 20)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: UUID.self) { listId in
                ListDetailRoute(listId: listId, lists: lists)
            }
            #if DEBUG
            .onAppear {
                // Screenshot harness: `-B1ProduceReview` / `-FinalCatalogReview` seed + jump into detail.
                guard path.isEmpty else { return }
                if ProduceReviewSeed.isRequested, !didAutoOpenProduceReview,
                   let list = lists.first(where: { $0.name == ProduceReviewSeed.listName }) {
                    didAutoOpenProduceReview = true
                    ActiveListResolver.setActive(list)
                    path.append(list.id)
                    return
                }
                if FinalCatalogReviewSeed.isRequested, !didAutoOpenFinalCatalogReview,
                   let list = lists.first(where: { $0.name == FinalCatalogReviewSeed.listName }) {
                    didAutoOpenFinalCatalogReview = true
                    ActiveListResolver.setActive(list)
                    path.append(list.id)
                }
            }
            #endif
            .fullScreenCover(item: $sheetMode) { mode in
                switch mode {
                case .create:
                    EditListSheet(mode: .create) { name, description, icon, tint in
                        if let list = GroceryListService.createList(
                            name: name,
                            description: description,
                            iconName: icon,
                            tintHex: tint,
                            context: modelContext
                        ) {
                            path.append(list.id)
                        }
                    }
                case .edit(let list):
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
            }
        }
    }

    @ViewBuilder
    private func listLink(for list: GroceryList, isActive: Bool) -> some View {
        NavigationLink(value: list.id) {
            ListCardView(list: list, isActive: isActive)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            ActiveListResolver.setActive(list)
        })
        .contextMenu {
            listContextMenu(for: list)
        }
    }

    private var availableTemplates: [ListStarterTemplate] {
        let existingNames = Set(lists.map { $0.name.lowercased().trimmingCharacters(in: .whitespaces) })
        return GroceryListService.starterTemplates.filter { template in
            !existingNames.contains(template.name.lowercased().trimmingCharacters(in: .whitespaces))
        }
    }

    @ViewBuilder
    private var starterTemplatesSection: some View {
        let templates = availableTemplates
        if !templates.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Start faster")
                    .appSectionLabel()
                    .adaptiveHorizontalPadding()

                VStack(spacing: 10) {
                    ForEach(templates) { template in
                        ListStarterTemplateCard(template: template) {
                            createFromTemplate(template)
                        }
                    }
                }
                .adaptiveHorizontalPadding()
            }
        }
    }

    private func createFromTemplate(_ template: ListStarterTemplate) {
        HapticsService.add()
        if let list = GroceryListService.createList(
            name: template.name,
            iconName: template.iconName,
            tintHex: template.tintHex,
            context: modelContext
        ) {
            path.append(list.id)
        }
    }

    @ViewBuilder
    private func listContextMenu(for list: GroceryList) -> some View {
        Button {
            sheetMode = .edit(list)
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        Button {
            sheetMode = .edit(list)
        } label: {
            Label("Change Color & Icon", systemImage: "paintpalette")
        }
        Button {
            if let duplicate = GroceryListService.duplicateList(list, context: modelContext) {
                path.append(duplicate.id)
                ActiveListResolver.setActive(duplicate)
            }
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        Button {
            UIPasteboard.general.string = GroceryListShareBuilder.copyText(for: list, context: modelContext)
        } label: {
            Label("Copy as Text", systemImage: AppIcons.clipboard)
        }
    }
}

private struct ListDetailRoute: View {
    @State private var listId: UUID
    let lists: [GroceryList]

    init(listId: UUID, lists: [GroceryList]) {
        _listId = State(initialValue: listId)
        self.lists = lists
    }

    var body: some View {
        if let list = lists.first(where: { $0.id == listId }) {
            ListDetailView(list: list) { newListId in
                listId = newListId
            }
            .id(listId)
        }
    }
}

#Preview {
    MyListsView()
        .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
