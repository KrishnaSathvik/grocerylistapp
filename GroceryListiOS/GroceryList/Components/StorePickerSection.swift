import SwiftUI

struct StorePickerSection: View {
    @Binding var selectedStoreId: String?

    private static let noneTag = "__none__"

    private var stores: [SeedData.StoreDefinition] {
        SeedData.loadStoreDefinitions()
    }

    private var pickerSelection: Binding<String> {
        Binding(
            get: { selectedStoreId ?? Self.noneTag },
            set: { selectedStoreId = $0 == Self.noneTag ? nil : $0 }
        )
    }

    var body: some View {
        Section("Store") {
            Picker("Store", selection: pickerSelection) {
                Text("None").tag(Self.noneTag)
                ForEach(stores, id: \.id) { store in
                    Text(store.label).tag(store.id)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }
}

#Preview {
    Form {
        StorePickerSection(selectedStoreId: .constant("costco"))
    }
}
