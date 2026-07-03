import Foundation
import UIKit

enum AppSupport {
    static var feedbackEmail: String { AppConfig.feedbackEmail }
    static var marketingPageURL: URL? { AppConfig.marketingPageURL }
    static var privacyPolicyURL: URL? { AppConfig.privacyPolicyURL }
    static var supportPageURL: URL? { AppConfig.supportPageURL }

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return identifier
    }

    static func diagnostics(includeAppearance: Bool) -> String {
        var lines = [
            "App version: \(appVersion)",
            "Build: \(buildNumber)",
            "iOS version: \(UIDevice.current.systemVersion)",
            "Device: \(deviceModel)",
        ]
        if includeAppearance {
            lines.append("Appearance: \(AppSettings.preferredColorScheme.label)")
        }
        return lines.joined(separator: "\n")
    }
}

enum FeedbackType: String, CaseIterable, Identifiable {
    case support = "Support"
    case bugReport = "Bug Report"
    case featureIdea = "Feature Idea"
    case general = "General Feedback"

    var id: String { rawValue }

    var emailSubject: String {
        switch self {
        case .support:
            return "Groceries — Smart Lists Support"
        default:
            return "Groceries — Smart Lists Feedback — \(rawValue)"
        }
    }
}
