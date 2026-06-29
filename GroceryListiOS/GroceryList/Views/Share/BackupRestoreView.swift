import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupRestoreView: View {
    enum Mode {
        case backup
        case restore
    }

    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    let mode: Mode

    @State private var showFileImporter = false
    @State private var shareBackupURL: ShareableBackupURL?
    @State private var statusMessage: String?
    @State private var pendingRestore: PendingRestore?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(mode == .backup ? backupDescription : restoreDescription)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .padding(.horizontal, 4)

                if mode == .backup {
                    ImportExportActionCard(
                        title: "Create Backup File",
                        subtitle: "Save \(BackupExportService.backupFileName) to Files or AirDrop",
                        icon: "externaldrive.fill",
                        tint: AppColors.accentPrimary,
                        action: exportBackup
                    )

                    ImportExportInfoCallout(
                        text: "Backup files include all your lists and items. Keep the file somewhere safe before deleting the app or switching phones."
                    )
                } else {
                    ImportExportActionCard(
                        title: "Choose Backup File",
                        subtitle: "Select a backup file saved from Grocery List",
                        icon: "arrow.clockwise.circle.fill",
                        tint: AppColors.accentSuccess,
                        action: { showFileImporter = true }
                    )

                    ImportExportInfoCallout(
                        text: "Restoring adds lists from your backup file. Your existing lists stay on this device."
                    )
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
            .padding(.bottom, 8)
        }
        .background(AppColors.backgroundGrouped)
        .navigationTitle(mode == .backup ? "Back Up All Data" : "Restore Backup")
        .navigationBarTitleDisplayMode(.inline)
        .settingsSubpageStyle()
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            handleBackupSelection(result)
        }
        .sheet(item: $shareBackupURL) { backup in
            ActivityShareSheet(items: [backup.url]) {
                shareBackupURL = nil
            }
        }
        .sheet(item: $pendingRestore) { pending in
            BackupRestorePreviewSheet(
                preview: pending.preview,
                onRestore: {
                    restoreBackup(data: pending.data)
                    pendingRestore = nil
                },
                onCancel: {
                    pendingRestore = nil
                }
            )
        }
        .alert(mode == .backup ? "Backup" : "Restore Backup", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private var backupDescription: String {
        "Export every list and item into one backup file you can save to Files, iCloud Drive, or AirDrop."
    }

    private var restoreDescription: String {
        "Import a saved backup file to bring your lists back to this device."
    }

    private func exportBackup() {
        do {
            let data = try BackupExportService.exportJSON(lists: lists)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(BackupExportService.backupFileName)
            try data.write(to: url, options: .atomic)
            shareBackupURL = ShareableBackupURL(url: url)
        } catch {
            statusMessage = "Couldn't create backup file."
        }
    }

    private func handleBackupSelection(_ result: Result<[URL], Error>) {
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
                let preview = try BackupExportService.preview(from: data)
                pendingRestore = PendingRestore(data: data, preview: preview)
            } catch {
                statusMessage = "That backup file couldn't be read."
            }
        }
    }

    private func restoreBackup(data: Data) {
        do {
            let listCount = try BackupExportService.importJSON(data, context: modelContext)
            statusMessage = "Imported \(listCount) list\(listCount == 1 ? "" : "s") from backup."
            HapticsService.importSuccess()
        } catch {
            statusMessage = "Couldn't restore that backup file."
        }
    }
}

private struct ShareableBackupURL: Identifiable {
    let id = UUID()
    let url: URL
}

private struct PendingRestore: Identifiable {
    let id = UUID()
    let data: Data
    let preview: BackupExportService.BackupPreview
}

private struct BackupRestorePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let preview: BackupExportService.BackupPreview
    let onRestore: () -> Void
    let onCancel: () -> Void

    private var previewListNames: [String] {
        Array(preview.listNames.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Restore this backup?")
                            .font(AppTypography.onboardingTitle)
                            .foregroundStyle(AppColors.ink)
                            .multilineTextAlignment(.center)

                        Text("Lists will be added to your device. Existing lists stay in place.")
                            .font(AppTypography.metadata)
                            .foregroundStyle(AppColors.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 0) {
                        summaryRow("Lists", value: "\(preview.listCount)")
                        SettingsDivider()
                        summaryRow("Items", value: "\(preview.itemCount)")

                        if !previewListNames.isEmpty {
                            SettingsDivider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Includes")
                                    .font(AppTypography.caption.weight(.semibold))
                                    .foregroundStyle(AppColors.inkSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)

                                ForEach(previewListNames, id: \.self) { name in
                                    Text(name)
                                        .font(AppTypography.itemTitle)
                                        .foregroundStyle(AppColors.ink)
                                        .padding(.horizontal, 16)
                                }

                                if preview.listNames.count > previewListNames.count {
                                    Text("+ \(preview.listNames.count - previewListNames.count) more list\(preview.listNames.count - previewListNames.count == 1 ? "" : "s")")
                                        .font(AppTypography.metadata)
                                        .foregroundStyle(AppColors.inkSecondary)
                                        .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 12)
                        }
                    }
                    .background(AppColors.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                    VStack(spacing: 10) {
                        Button("Restore as New Data") {
                            onRestore()
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityLabel("Restore as new data")

                        Button("Cancel") {
                            onCancel()
                            dismiss()
                        }
                        .font(AppTypography.button)
                        .foregroundStyle(AppColors.inkSecondary)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(AppColors.backgroundGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func summaryRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.itemTitle)
                .foregroundStyle(AppColors.ink)
            Spacer()
            Text(value)
                .font(AppTypography.metadata.weight(.semibold))
                .foregroundStyle(AppColors.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview("Backup") {
    NavigationStack {
        BackupRestoreView(mode: .backup)
    }
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}

#Preview("Restore") {
    NavigationStack {
        BackupRestoreView(mode: .restore)
    }
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
