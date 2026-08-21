import Foundation

/// A single square on the 4x4 grid. (0,0) is the bottom-left square.
struct GridPosition: Equatable, Hashable {
    var col: Int
    var row: Int

    func applying(_ direction: Direction) -> GridPosition {
        let delta = direction.delta
        return GridPosition(col: col + delta.col, row: row + delta.row)
    }

    func isInBounds(gridSize: Int) -> Bool {
        (0..<gridSize).contains(col) && (0..<gridSize).contains(row)
    }
}
