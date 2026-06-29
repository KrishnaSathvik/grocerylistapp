import UIKit

enum HapticsService {
    static func check() {
        guard AppSettings.enableHaptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func add() {
        guard AppSettings.enableHaptics else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func delete() {
        guard AppSettings.enableHaptics else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func stepper() {
        guard AppSettings.enableHaptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func undo() {
        guard AppSettings.enableHaptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        guard AppSettings.enableHaptics else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func navigation() {
        guard AppSettings.enableHaptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func importSuccess() {
        guard AppSettings.enableHaptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
