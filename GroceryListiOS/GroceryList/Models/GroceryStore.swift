import Foundation
import SwiftData

@Model
final class GroceryStore {
    @Attribute(.unique) var id: String
    var label: String
    var domain: String?
    var colorHex: String
    var isCustom: Bool
    var sortOrder: Int

    init(
        id: String,
        label: String,
        domain: String? = nil,
        colorHex: String,
        isCustom: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.label = label
        self.domain = domain
        self.colorHex = colorHex
        self.isCustom = isCustom
        self.sortOrder = sortOrder
    }
}
