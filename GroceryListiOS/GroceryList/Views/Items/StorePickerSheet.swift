import SwiftUI
import SwiftData

struct StorePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Binding var selectedStoreId: String?

    var itemName: String?

    @State private var searchText = ""

    private var allStores: [StoreService.StoreInfo] {
        StoreService.allStores(context: modelContext)
    }

    private var filteredStores: [StoreService.StoreInfo] {
        guard !searchText.isEmpty else { return allStores }
        return allStores.filter {
            $0.label.localizedCaseInsensitiveContains(searchText)
                || $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var popularStores: [StoreService.StoreInfo] {
        let popularIds = ["costco", "walmart", "target", "traderjoes", "wholefoods", "hmart"]
        return filteredStores.filter { popularIds.contains($0.id) }
    }

    private var otherStores: [StoreService.StoreInfo] {
        let popularIds = Set(popularStores.map(\.id))
        return filteredStores.filter { !popularIds.contains($0.id) }
    }

    private var currentStoreLabel: String {
        guard let storeId = selectedStoreId, !storeId.isEmpty else { return "No store" }
        let label = StoreService.label(for: storeId, context: modelContext)
        return label == "Unassigned" ? "No store" : label
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let itemName {
                    itemContextHeader(name: itemName)
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                }

                searchField
                    .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        noStoreRow

                        if !popularStores.isEmpty {
                            sectionHeader("Popular Stores")
                            ForEach(popularStores) { store in
                                storeRow(store: store)
                            }
                        }

                        if !otherStores.isEmpty {
                            sectionHeader("All Stores")
                            ForEach(otherStores) { store in
                                storeRow(store: store)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .adaptiveScreenContent()
            .frame(maxHeight: .infinity, alignment: .top)
            .background(AppColors.backgroundGrouped)
            .navigationTitle("Choose Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .accessibilityLabel("Done choosing store")
                }
            }
        }
    }

    private func itemContextHeader(name: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.ink)
                .lineLimit(2)
            Text("Currently: \(currentStoreLabel)")
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.inkSecondary)
            TextField("Search stores", text: $searchText)
                .font(AppTypography.itemTitle)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Search stores")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.metadata.weight(.semibold))
            .foregroundStyle(AppColors.inkSecondary)
            .padding(.horizontal, 4)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var noStoreRow: some View {
        storeRow(id: nil, label: "No store", isSelected: selectedStoreId == nil)
    }

    private func storeRow(store: StoreService.StoreInfo) -> some View {
        storeRow(id: store.id, label: store.label, isSelected: selectedStoreId == store.id)
    }

    @ViewBuilder
    private func storeRow(id: String?, label: String, isSelected: Bool) -> some View {
        Button {
            selectedStoreId = id
            HapticsService.selection()
            dismiss()
        } label: {
            HStack(spacing: 14) {
                if let id {
                    StoreLogoView(storeId: id, size: 38, cornerRadius: 10)
                } else {
                    noStoreIcon
                }

                Text(label)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.accentPrimary)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AppColors.accentSuccess.opacity(0.12) : AppColors.backgroundPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AppColors.accentSuccess.opacity(0.28) : AppColors.cardBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
        .accessibilityLabel("\(label)\(isSelected ? ", selected" : "")")
    }

    private var noStoreIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.backgroundPrimary)
            Image(systemName: "nosign")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppColors.inkSecondary)
        }
        .frame(width: 38, height: 38)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
}
