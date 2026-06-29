import UIKit

enum AppIconError: LocalizedError {
    case alternateIconsUnavailable

    var errorDescription: String? {
        "App icon changes work on a physical iPhone. They aren't available in the simulator."
    }
}

enum AppIconService {
    static var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    static var currentAlternateIconName: String? {
        UIApplication.shared.alternateIconName
    }

    static var currentOption: AppIconOption {
        AppIconOption.matching(alternateIconName: currentAlternateIconName)
    }

    @MainActor
    static func setIcon(_ option: AppIconOption) async throws {
        guard supportsAlternateIcons else {
            throw AppIconError.alternateIconsUnavailable
        }
        guard option.alternateIconName != currentAlternateIconName else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UIApplication.shared.setAlternateIconName(option.alternateIconName) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
