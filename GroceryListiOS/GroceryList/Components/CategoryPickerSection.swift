import SwiftUI

struct CategoryPickerSection: View {
    @Binding var selectedCategoryId: String

    private var categories: [SeedData.CategoryDefinition] {
        SeedData.loadCategories()?.categories ?? []
    }

    var body: some View {
        Section("Category") {
            Picker("Category", selection: $selectedCategoryId) {
                ForEach(categories, id: \.id) { category in
                    HStack {
                        EmojiLabel(emoji: category.emoji, size: 22)
                        Text(category.label)
                    }
                    .tag(category.id)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }
}

#Preview {
    Form {
        CategoryPickerSection(selectedCategoryId: .constant("dairy"))
    }
}
