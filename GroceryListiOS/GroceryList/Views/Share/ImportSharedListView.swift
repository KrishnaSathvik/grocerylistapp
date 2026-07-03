import SwiftUI
import SwiftData
import UIKit
import VisionKit

struct ImportSharedListView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var showScanner = false
    @State private var sharedText = ""
    @State private var pendingImport: ParsedSharedList?
    @State private var statusMessage: String?
    @State private var successMessage: String?

    private var isScannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    private var trimmedSharedText: String {
        sharedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Bring in a grocery list someone shared with you.")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .padding(.horizontal, 4)

                scanOption
                pasteCard
            }
            .padding(.vertical, 16)
            .padding(.bottom, 8)
            .adaptiveScreenContent()
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

    private var scanOption: some View {
        Group {
            if isScannerAvailable {
                ImportOptionCard(
                    title: "Scan QR Code",
                    subtitle: "Use your camera to scan a Groceries — Smart Lists code.",
                    icon: AppIcons.qrCode,
                    tint: AppColors.accentSuccess,
                    isEnabled: true
                ) {
                    showScanner = true
                }
            } else {
                ImportOptionCard(
                    title: "Scan QR Code",
                    subtitle: "QR scanning is available on a real device.",
                    icon: AppIcons.qrCode,
                    tint: AppColors.inkSecondary,
                    isEnabled: false,
                    action: {}
                )
            }
        }
    }

    private var pasteCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: AppIcons.clipboard)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.accentPrimary)
                    .frame(width: 42, height: 42)
                    .background(AppColors.accentPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Paste Shared Code")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.ink)
                    Text("Paste a GLIST1 import code from QR scan, Messages, or email.")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                }
            }

            TextField("Paste shared code here", text: $sharedText, axis: .vertical)
                .lineLimit(4...8)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(AppTypography.itemTitle)
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
                .background(AppColors.backgroundGrouped)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
                .accessibilityLabel("Shared list code")

            HStack(spacing: 12) {
                Button("Paste from Clipboard") {
                    if let clipboard = UIPasteboard.general.string {
                        sharedText = clipboard
                    }
                }
                .font(AppTypography.button)
                .foregroundStyle(AppColors.accentPrimary)

                Spacer(minLength: 0)
            }

            Button("Import List") {
                handleImportRaw(sharedText)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(trimmedSharedText.isEmpty)
            .opacity(trimmedSharedText.isEmpty ? 0.48 : 1)
            .accessibilityLabel("Import shared list")
        }
        .appCard()
    }

    private func handleImportRaw(_ raw: String) {
        guard let parsed = ListCodec.parseSharedList(from: raw), !parsed.items.isEmpty else {
            statusMessage = "This shared list code doesn’t look valid."
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

private struct ImportOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(isEnabled ? 0.14 : 0.09))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.ink)
                    Text(subtitle)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if isEnabled {
                    Image(systemName: AppIcons.chevron)
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.inkSecondary.opacity(0.6))
                }
            }
            .appCard(padding: 14)
            .opacity(isEnabled ? 1 : 0.72)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
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
