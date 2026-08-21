import Foundation

/// One "instruction" a kid can add to the dino's program by tapping an arrow button.
/// This is the smallest unit of "code" in the app: a program is just `[Direction]`.
enum Direction: String, CaseIterable, Identifiable {
    case up, down, left, right

    var id: String { rawValue }

    /// SF Symbol used for both the arrow button and the program-strip chip.
    var symbolName: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }

    /// How this direction changes a grid coordinate. Grid uses (col, row) with
    /// row increasing upward, so "up" is +1 row, matching what a kid expects
    /// when they tap the up arrow.
    var delta: (col: Int, row: Int) {
        switch self {
        case .up: return (0, 1)
        case .down: return (0, -1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }
}
