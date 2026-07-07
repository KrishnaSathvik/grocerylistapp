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

    private var isScannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    private var trimmedSharedText: String {
        sharedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isScannerAvailable {
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
                    if isScannerAvailable {
                        Text("or paste a link or list")
                            .font(AppTypography.metadata)
                            .foregroundStyle(AppColors.inkSecondary)
                            .frame(maxWidth: .infinity)
                    }

                    TextField("Share link or grocery list", text: $sharedText, axis: .vertical)
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
                        .accessibilityLabel("Share link or grocery list")

                    Button {
                        handleImportRaw(sharedText)
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
                handleImportRaw(value)
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
        handleImportRaw(clipboard)
    }

    private func handleImportRaw(_ raw: String) {
        isImporting = true
        Task {
            let parsed: ParsedSharedList?
            if let shortId = ListCodec.extractShortShareId(from: raw) {
                parsed = await ShareLinkService.fetchSharedList(id: shortId)
            } else if let linkParsed = ListCodec.parseSharedList(from: raw) {
                parsed = linkParsed
            } else {
                parsed = PlainTextListParser.parse(raw)
            }

            isImporting = false
            guard let parsed, !parsed.items.isEmpty else {
                if raw.contains("☐") || raw.contains("[ ]") || raw.contains("[") {
                    statusMessage = "Couldn't read any grocery items from that text."
                } else {
                    statusMessage = "Paste a share link or a grocery list copied from this app."
                }
                return
            }
            pendingImport = parsed
            HapticsService.selection()
        }
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
