import SwiftUI
import SwiftData

struct EditListSheet: View {
    @Environment(\.dismiss) private var dismiss

    enum Mode {
        case create
        case edit(GroceryList)
    }

    let mode: Mode
    let onSave: (String, String?, String, String) -> Void

    @State private var name: String
    @State private var description: String
    @State private var selectedIcon: String
    @State private var selectedTint: String

    init(mode: Mode, onSave: @escaping (String, String?, String, String) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _description = State(initialValue: "")
            _selectedIcon = State(initialValue: "cart.fill")
            _selectedTint = State(initialValue: GroceryListService.listTintOptions[0])
        case .edit(let list):
            _name = State(initialValue: list.name)
            _description = State(initialValue: list.listDescription ?? "")
            _selectedIcon = State(initialValue: list.iconName)
            _selectedTint = State(initialValue: list.tintHex)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    previewCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("List name")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        TextField("Weekly Groceries", text: $name)
                            .font(AppTypography.itemTitle)
                            .padding(14)
                            .background(AppColors.backgroundPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        TextField("Optional", text: $description, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(14)
                            .background(AppColors.backgroundPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(GroceryListService.listTintOptions, id: \.self) { hex in
                                Circle()
                                    .fill(AppColors.colorHex(hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedTint == hex ? AppColors.accentPrimary : AppColors.cardBorder.opacity(0.5), lineWidth: selectedTint == hex ? 3 : 1)
                                    )
                                    .onTapGesture {
                                        selectedTint = hex
                                        HapticsService.selection()
                                    }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Icon")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                            ForEach(GroceryListService.listIconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                    HapticsService.selection()
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(selectedIcon == icon ? .white : AppColors.ink)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            selectedIcon == icon
                                                ? AppColors.colorHex(selectedTint)
                                                : AppColors.filterUnselected
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(selectedIcon == icon ? AppColors.accentPrimary : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .adaptiveScreenContent()
                .padding(.bottom, 24)
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle(isEditing ? "Edit List" : "New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        onSave(name, description, selectedIcon, selectedTint)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.colorHex(selectedTint).opacity(0.16))
                    .frame(width: AppSpacing.listIconSize, height: AppSpacing.listIconSize)
                Image(systemName: selectedIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.colorHex(selectedTint))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(name.isEmpty ? "List name" : name)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                Text(description.isEmpty ? "Optional description" : description)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppColors.heroGradientTop.opacity(0.45), AppColors.backgroundPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppColors.cardShadow, radius: 10, x: 0, y: 4)
    }
}
