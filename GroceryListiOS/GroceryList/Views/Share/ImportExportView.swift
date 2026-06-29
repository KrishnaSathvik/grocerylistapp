import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct ImportExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ImportCoordinator.self) private var importCoordinator

    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    @State private var showScanner = false
    @State private var showFileImporter = false
    @State private var shareBackupURL: URL?
    @State private var statusMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Import")

                ImportExportActionCard(
                    title: "Paste from clipboard",
                    subtitle: "Import a shared list from text",
                    icon: AppIcons.clipboard,
                    tint: AppColors.accentPrimary,
                    action: pasteFromClipboard
                )

                ImportExportActionCard(
                    title: "Scan QR code",
                    subtitle: "Open a list shared as a QR code",
                    icon: AppIcons.qrCode,
                    tint: AppColors.accentSuccess,
                    action: { showScanner = true }
                )

                ImportExportActionCard(
                    title: "Import JSON backup",
                    subtitle: "Restore from a saved backup file",
                    icon: "doc.badge.plus",
                    tint: AppColors.colorHex("#8B6F8E"),
                    action: { showFileImporter = true }
                )

                sectionHeader("Export")

                ImportExportActionCard(
                    title: "Export JSON backup",
                    subtitle: "Save all lists to a file",
                    icon: "square.and.arrow.up.on.square",
                    tint: AppColors.accentPrimary,
                    action: exportJSONBackup
                )

                ImportExportInfoCallout(
                    text: "Share links and QR codes use the same format as the web app (up to \(ListCodec.maxLinkItems) items). JSON backup includes all lists with no item limit."
                )
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
            .padding(.bottom, 8)
        }
        .background(AppColors.backgroundGrouped)
        .navigationTitle("Import / Export")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanner) {
            QRScannerScreen { value in
                handleImportRaw(value)
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleBackupImport(result)
        }
        .sheet(item: $shareBackupURL) { url in
            ActivityShareSheet(items: [url]) {
                shareBackupURL = nil
            }
        }
        .alert("Import / Export", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .appSectionLabel()
            .padding(.horizontal, 4)
            .padding(.top, 4)
    }

    private func pasteFromClipboard() {
        guard let raw = UIPasteboard.general.string, !raw.isEmpty else {
            statusMessage = "Clipboard is empty."
            return
        }
        handleImportRaw(raw)
    }

    private func handleImportRaw(_ raw: String) {
        if importCoordinator.load(from: raw) {
            HapticsService.selection()
        } else {
            statusMessage = importCoordinator.statusMessage ?? "Couldn't read import data."
            importCoordinator.clearStatus()
        }
    }

    private func exportJSONBackup() {
        do {
            let data = try BackupExportService.exportJSON(lists: lists)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("grocery-list-backup-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: url, options: .atomic)
            shareBackupURL = url
        } catch {
            statusMessage = "Couldn't export backup."
        }
    }

    private func handleBackupImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure:
            statusMessage = "Couldn't open backup file."
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                statusMessage = "Couldn't access backup file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let listCount = try BackupExportService.importJSON(data, context: modelContext)
                statusMessage = "Imported \(listCount) list\(listCount == 1 ? "" : "s")."
                HapticsService.importSuccess()
            } catch {
                statusMessage = "Invalid backup file."
            }
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    NavigationStack {
        ImportExportView()
    }
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
    .environment(ImportCoordinator())
}
