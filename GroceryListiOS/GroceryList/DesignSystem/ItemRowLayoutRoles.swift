import SwiftUI

/// Stage 1 — `LayoutValueKey` role tags so optional ItemRow children are not index-fragile.
/// Stage 2 surface extraction is paused until the revised Candidate B visual gate is reviewed.
/// Other surfaces in Stage 3 should copy this pattern with their own role enums rather than
/// depending on a mega adaptive-row container.
enum ItemRowLayoutRole: Equatable {
    case checkbox
    case thumbnail
    /// Product name only — used for one-line ideal / protected title width.
    case title
    /// Category/store chips under the title — height only; must not inflate the title floor.
    case metadata
    case stepper
    case edit
}

struct ItemRowLayoutRoleKey: LayoutValueKey {
    static let defaultValue: ItemRowLayoutRole? = nil
}

extension View {
    func itemRowLayoutRole(_ role: ItemRowLayoutRole) -> some View {
        layoutValue(key: ItemRowLayoutRoleKey.self, value: role)
    }
}

#if DEBUG
enum ItemRowCandidateDebug {
    static var lastSelected: ItemRowCandidate?
}

extension ItemRowCandidate {
    var debugCode: String {
        switch self {
        case .inline: return "A"
        case .splitStepper: return "B"
        case .stackedControls: return "C"
        }
    }
}
#endif
