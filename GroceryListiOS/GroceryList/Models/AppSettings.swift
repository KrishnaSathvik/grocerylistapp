import Foundation
import SwiftUI

enum AppColorSchemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppSettings {
    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let defaultViewMode = "defaultViewMode"
        static let categoryOrder = "categoryOrder"
        static let enableHaptics = "enableHaptics"
        static let showCompletedInStoreView = "showCompletedInStoreView"
        static let preferredColorScheme = "preferredColorScheme"
        static let activeListId = "activeListId"
        static let customCategories = "customCategories"
    }

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    static var defaultViewMode: ListFilterMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: Keys.defaultViewMode),
                  let mode = ListFilterMode(rawValue: raw) else {
                return .all
            }
            return mode
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Keys.defaultViewMode) }
    }

    static var enableHaptics: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.enableHaptics) == nil { return true }
            return UserDefaults.standard.bool(forKey: Keys.enableHaptics)
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.enableHaptics) }
    }

    static var showCompletedInStoreView: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.showCompletedInStoreView) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.showCompletedInStoreView) }
    }

    static var preferredColorScheme: AppColorSchemePreference {
        get {
            guard let raw = UserDefaults.standard.string(forKey: Keys.preferredColorScheme),
                  let pref = AppColorSchemePreference(rawValue: raw) else {
                return .system
            }
            return pref
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Keys.preferredColorScheme) }
    }

    static var activeListId: String? {
        get { UserDefaults.standard.string(forKey: Keys.activeListId) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.activeListId) }
    }

    static var categoryOrder: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: Keys.categoryOrder)
                ?? defaultCategoryOrder
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.categoryOrder)
        }
    }

    static var defaultCategoryOrder: [String] {
        let fromCatalog = GroceryCatalog.defaultCategoryOrder
        if !fromCatalog.isEmpty { return fromCatalog }
        return SeedData.loadCategories()?.categories.map(\.id) ?? []
    }

    static func resetCategoryOrder() {
        UserDefaults.standard.removeObject(forKey: Keys.categoryOrder)
    }

    static var customCategories: [CategoryService.CategoryInfo] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.customCategories),
                  let categories = try? JSONDecoder().decode([CategoryService.CategoryInfo].self, from: data) else {
                return []
            }
            return categories
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Keys.customCategories)
            }
        }
    }
}

enum ListFilterMode: String, CaseIterable, Identifiable {
    case all = "All"
    case store = "Store"
    case category = "Category"

    var id: String { rawValue }
}
