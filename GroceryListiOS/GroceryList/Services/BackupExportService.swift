import Foundation
import SwiftData

enum BackupExportService {
    static let backupVersion = 1

    struct BackupFile: Codable {
        let version: Int
        let exportedAt: Date
        let lists: [BackupList]
    }

    struct BackupList: Codable {
        let id: UUID
        let name: String
        let listDescription: String?
        let sortOrder: Int
        let iconName: String
        let tintHex: String
        let items: [BackupItem]
    }

    struct BackupItem: Codable {
        let name: String
        let normalizedName: String
        let quantityValue: Int?
        let quantityText: String?
        let categoryId: String
        let storeId: String?
        let isCompleted: Bool
        let notes: String?
        let sortOrder: Int
    }

    struct BackupPreview: Equatable {
        let listCount: Int
        let itemCount: Int
        let listNames: [String]
    }

    static func preview(from data: Data) throws -> BackupPreview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupFile.self, from: data)
        guard payload.version == backupVersion else {
            throw BackupError.unsupportedVersion
        }
        let itemCount = payload.lists.reduce(0) { $0 + $1.items.count }
        return BackupPreview(
            listCount: payload.lists.count,
            itemCount: itemCount,
            listNames: payload.lists.map(\.name)
        )
    }

    static let backupFileName = "GroceryListBackup.grocerybackup"

    static func exportJSON(lists: [GroceryList]) throws -> Data {
        let payload = BackupFile(
            version: backupVersion,
            exportedAt: .now,
            lists: lists.filter { !$0.isArchived }.map(backupList(from:))
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    static func importJSON(_ data: Data, context: ModelContext) throws -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupFile.self, from: data)
        guard payload.version == backupVersion else {
            throw BackupError.unsupportedVersion
        }

        var importedCount = 0
        for backup in payload.lists {
            let list = GroceryList(
                id: UUID(),
                name: backup.name,
                listDescription: backup.listDescription,
                sortOrder: backup.sortOrder,
                iconName: backup.iconName,
                tintHex: backup.tintHex
            )
            context.insert(list)

            for (index, item) in backup.items.enumerated() {
                let groceryItem = GroceryItem(
                    name: item.name,
                    normalizedName: item.normalizedName,
                    quantityValue: item.quantityValue,
                    quantityText: item.quantityText,
                    categoryId: item.categoryId,
                    storeId: item.storeId,
                    isCompleted: item.isCompleted,
                    imageAssetName: ProductImageCatalog.assetName(for: item.normalizedName),
                    sortOrder: index,
                    notes: item.notes,
                    completedAt: item.isCompleted ? .now : nil,
                    list: list
                )
                context.insert(groceryItem)
                list.items.append(groceryItem)
                importedCount += 1
            }
            importedCount += 0
        }
        try context.save()
        return payload.lists.count
    }

    enum BackupError: Error {
        case unsupportedVersion
    }

    private static func backupList(from list: GroceryList) -> BackupList {
        BackupList(
            id: list.id,
            name: list.name,
            listDescription: list.listDescription,
            sortOrder: list.sortOrder,
            iconName: list.iconName,
            tintHex: list.tintHex,
            items: list.items
                .filter { !$0.isArchived }
                .sorted { $0.sortOrder < $1.sortOrder }
                .map(backupItem(from:))
        )
    }

    private static func backupItem(from item: GroceryItem) -> BackupItem {
        BackupItem(
            name: item.name,
            normalizedName: item.normalizedName,
            quantityValue: item.quantityValue,
            quantityText: item.quantityText,
            categoryId: item.categoryId,
            storeId: item.storeId,
            isCompleted: item.isCompleted,
            notes: item.notes,
            sortOrder: item.sortOrder
        )
    }
}
