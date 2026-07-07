import SwiftUI
import SwiftData
import UIKit
import VisionKit

struct ImportSharedListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showScanner = false
    @State private var sharedText = ""
    @State private var pendingImport: ParsedSharedList?
    @State private var statusMessage: String?
    @State private var successMessage: String?
    @State private var isImporting = false

    private var isScannerSupported: Bool {
        DataScannerViewController.isSupported
    }

    private var trimmedSharedText: String {
        sharedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isScannerSupported {
                    Button {
                        showScanner = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: AppIcons.qrCode)
                            Text("Scan QR Code")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                VStack(alignment: .leading, spacing: 12) {
                    if isScannerSupported {
                        Text("or paste a copied list")
                            .font(AppTypography.metadata)
                            .foregroundStyle(AppColors.inkSecondary)
                            .frame(maxWidth: .infinity)
                    }

                    TextField("Pasted grocery list", text: $sharedText, axis: .vertical)
                        .lineLimit(3...8)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(AppTypography.itemTitle)
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
                        .background(AppColors.backgroundGrouped)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                        .accessibilityLabel("Pasted grocery list")

                    Button {
                        handlePastedListText(sharedText)
                    } label: {
                        HStack(spacing: 8) {
                            if isImporting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Import List")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(trimmedSharedText.isEmpty || isImporting)
                    .opacity(trimmedSharedText.isEmpty || isImporting ? 0.48 : 1)

                    if hasClipboardContent {
                        Button("Paste from Clipboard") {
                            pasteFromClipboard()
                        }
                        .font(AppTypography.button)
                        .foregroundStyle(AppColors.accentPrimary)
                        .frame(maxWidth: .infinity)
                    }
                }
                .appCard()
            }
            .padding(.vertical, 16)
            .padding(.bottom, 8)
            .adaptiveScreenContent()
        }
        .background(AppColors.backgroundGrouped)
        .navigationTitle("Import a List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showScanner) {
            QRScannerScreen { value in
                handleScannedCode(value)
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
        .alert("Import a List", isPresented: Binding(
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
            Button("OK", role: .cancel) {
                successMessage = nil
                dismiss()
            }
        } message: {
            Text(successMessage ?? "")
        }
    }

    private var hasClipboardContent: Bool {
        guard let clipboard = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboard.isEmpty else {
            return false
        }
        return true
    }

    private func pasteFromClipboard() {
        guard let clipboard = UIPasteboard.general.string,
              !clipboard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Nothing to paste from your clipboard."
            return
        }
        sharedText = clipboard
        handlePastedListText(clipboard)
    }

    private func handleScannedCode(_ raw: String) {
        isImporting = true
        Task {
            let parsed = await parseShareLink(raw)
            isImporting = false
            presentParsedList(parsed, raw: raw, expectingPlainText: false)
        }
    }

    private func handlePastedListText(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if isShareLink(trimmed) {
            statusMessage = "Share links open automatically when you tap them. Paste a list copied with Copy as Text."
            return
        }

        isImporting = true
        Task {
            let parsed = PlainTextListParser.parse(trimmed)
            isImporting = false
            presentParsedList(parsed, raw: trimmed, expectingPlainText: true)
        }
    }

    private func isShareLink(_ raw: String) -> Bool {
        raw.contains("smartgrocerylists.app")
            || raw.hasPrefix("GLIST1:")
            || ListCodec.extractShortShareId(from: raw) != nil
    }

    private func parseShareLink(_ raw: String) async -> ParsedSharedList? {
        if let shortId = ListCodec.extractShortShareId(from: raw) {
            return await ShareLinkService.fetchSharedList(id: shortId)
        }
        return ListCodec.parseSharedList(from: raw)
    }

    private func presentParsedList(
        _ parsed: ParsedSharedList?,
        raw: String,
        expectingPlainText: Bool
    ) {
        guard let parsed, !parsed.items.isEmpty else {
            if expectingPlainText {
                if raw.contains("☐") || raw.contains("[ ]") || raw.contains("[") {
                    statusMessage = "Couldn't read any grocery items from that text."
                } else {
                    statusMessage = "Paste a grocery list copied with Copy as Text."
                }
            } else {
                statusMessage = "Couldn't import that QR code or share link."
            }
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
        sharedText = ""
        successMessage = "Imported \(list.name)"
        HapticsService.importSuccess()
    }
}

extension ParsedSharedList: Identifiable {
    var id: String {
        "\(listName ?? "list")-\(items.count)-\(items.first?.name ?? "")"
    }
}

#Preview {
    NavigationStack {
        ImportSharedListView()
    }
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
