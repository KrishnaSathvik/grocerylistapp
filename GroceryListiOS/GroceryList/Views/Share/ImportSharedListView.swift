import SwiftUI
import SwiftData
import UIKit
import VisionKit

struct ImportSharedListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    @State private var showScanner = false
    @State private var showPasteSheet = false
    @State private var pendingImport: ParsedSharedList?
    @State private var statusMessage: String?
    @State private var successMessage: String?

    private var isScannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Bring in a list someone shared with you. Imported lists are added as new lists on your device.")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .padding(.horizontal, 4)

                if isScannerAvailable {
                    ImportExportActionCard(
                        title: "Scan QR Code",
                        subtitle: "Use your camera to scan a Grocery List code",
                        icon: AppIcons.qrCode,
                        tint: AppColors.accentSuccess,
                        action: { showScanner = true }
                    )
                } else {
                    ImportExportActionCard(
                        title: "Scan QR Code",
                        subtitle: "Camera scanning isn't available here. Paste a shared list instead.",
                        icon: AppIcons.qrCode,
                        tint: AppColors.inkSecondary,
                        action: {}
                    )
                    .disabled(true)
                    .opacity(0.7)
                }

                ImportExportActionCard(
                    title: "Paste Shared Text",
                    subtitle: "Paste a list code from Messages, WhatsApp, or email",
                    icon: AppIcons.clipboard,
                    tint: AppColors.accentPrimary,
                    action: { showPasteSheet = true }
                )
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
            .padding(.bottom, 8)
        }
        .background(AppColors.backgroundGrouped)
        .navigationTitle("Import Shared List")
        .navigationBarTitleDisplayMode(.inline)
        .settingsSubpageStyle()
        .sheet(isPresented: $showScanner) {
            QRScannerScreen { value in
                handleImportRaw(value)
            }
        }
        .sheet(isPresented: $showPasteSheet) {
            PasteSharedTextSheet { raw in
                handleImportRaw(raw)
            }
        }
        .sheet(item: $pendingImport) { parsed in
            SharedListImportPreview(
                parsed: parsed,
                onImport: {
                    importList(parsed)
                    pendingImport = nil
                },
                onCancel: {
                    pendingImport = nil
                }
            )
        }
        .alert("Import Shared List", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
        .alert("Imported", isPresented: Binding(
            get: { successMessage != nil },
            set: { if !$0 { successMessage = nil } }
        )) {
            Button("OK", role: .cancel) { successMessage = nil }
        } message: {
            Text(successMessage ?? "")
        }
    }

    private func handleImportRaw(_ raw: String) {
        guard let parsed = ListCodec.parseSharedList(from: raw), !parsed.items.isEmpty else {
            statusMessage = "That doesn't look like a shared grocery list. Check the code and try again."
            return
        }
        pendingImport = parsed
        HapticsService.selection()
    }

    private func importList(_ parsed: ParsedSharedList) {
        let fallbackName = parsed.listName ?? "Imported List"
        guard let list = GroceryListService.importSharedList(
            name: fallbackName,
            items: parsed.items,
            context: modelContext
        ) else {
            statusMessage = "Couldn't import that list."
            return
        }
        successMessage = "Imported \(list.name)"
        HapticsService.importSuccess()
    }
}

extension ParsedSharedList: Identifiable {
    var id: String {
        "\(listName ?? "list")-\(items.count)-\(items.first?.name ?? "")"
    }
}

private struct PasteSharedTextSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    let onSubmit: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Paste the shared list code below.")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)

                TextField("Shared list code", text: $text, axis: .vertical)
                    .lineLimit(4...12)
                    .font(AppTypography.itemTitle)
                    .padding(14)
                    .background(AppColors.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                    .accessibilityLabel("Shared list code")

                Button("Paste from Clipboard") {
                    if let clipboard = UIPasteboard.general.string {
                        text = clipboard
                    }
                }
                .font(AppTypography.button)
                .foregroundStyle(AppColors.accentPrimary)

                Spacer()
            }
            .padding(AppSpacing.screenHorizontal)
            .padding(.top, 16)
            .background(AppColors.backgroundGrouped)
            .navigationTitle("Paste Shared Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        onSubmit(text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NavigationStack {
        ImportSharedListView()
    }
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
