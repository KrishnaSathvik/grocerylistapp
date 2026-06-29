import SwiftUI

enum AppIcons {
    static let add = "plus"
    static let share = "square.and.arrow.up"
    static let menu = "line.3.horizontal"
    static let more = "ellipsis.circle"
    static let editItem = "pencil"
    static let store = "storefront.fill"
    static let categories = "square.grid.2x2.fill"
    static let lists = "list.bullet"
    static let settings = "gearshape"
    static let chevron = "chevron.right"
    static let checkmarkFilled = "checkmark.circle.fill"
    static let circle = "circle"
    static let qrCode = "qrcode"
    static let clipboard = "doc.on.clipboard"

    static func categorySymbol(for categoryId: String) -> String {
        switch categoryId {
        case "produce": return "leaf.fill"
        case "dairy": return "cup.and.saucer.fill"
        case "meat": return "fork.knife"
        case "seafood": return "drop.fill"
        case "bakery": return "birthday.cake.fill"
        case "deli": return "takeoutbag.and.cup.and.straw.fill"
        case "frozen": return "snowflake"
        case "pantry": return "archivebox.fill"
        case "snacks": return "bag.fill"
        case "condiments": return "flame.fill"
        case "drinks": return "cup.and.saucer.fill"
        case "household": return "house.fill"
        case "health": return "heart.fill"
        case "baby": return "figure.and.child.holdinghands"
        case "pet": return "pawprint.fill"
        case "floral": return "camera.macro"
        default: return "cart.fill"
        }
    }
}
