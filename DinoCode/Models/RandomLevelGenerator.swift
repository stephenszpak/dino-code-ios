import Foundation

/// Procedurally builds a level for any level number past the hand-designed
/// ones (see `Levels.handcrafted`). Each level number is its own random seed,
/// so the same level always generates the same map for the whole app
/// session - re-selecting level 6 doesn't reshuffle its rocks.
enum RandomLevelGenerator {

    // MARK: - Tunables

    static let minObstacles = 1
    static let maxObstacles = 4
    /// Prefer a cookie that's at least this many grid steps from the start
    /// (Manhattan distance) so generated levels don't feel trivially easy.
    static let minCookieDistance = 3
    /// How many random obstacle layouts to try before giving up and falling
    /// back to a guaranteed-solvable empty-board level.
    static let maxAttempts = 200

    static func generate(levelNumber: Int, gridSize: Int) -> LevelConfig {
        var rng = SeededGenerator(seed: UInt64(levelNumber) &* 0x2545F4914F6CDD1D)
        let start = GridPosition(col: 0, row: 0)
        let allCells = (0..<gridSize).flatMap { row in
            (0..<gridSize).map { col in GridPosition(col: col, row: row) }
        }

        let farCookies = allCells.filter { $0 != start && manhattanDistance($0, start) >= minCookieDistance }
        let cookieCandidates = farCookies.isEmpty ? allCells.filter { $0 != start } : farCookies
        guard let cookie = cookieCandidates.randomElement(using: &rng) else {
            // Degenerate grid (shouldn't happen for gridSize >= 2); fall back
            // to the opposite corner from start.
            let fallbackCookie = GridPosition(col: gridSize - 1, row: gridSize - 1)
            return LevelConfig(number: levelNumber, start: start, cookie: fallbackCookie, obstacles: [])
        }

        for _ in 0..<maxAttempts {
            let obstacleCount = Int.random(in: minObstacles...maxObstacles, using: &rng)
            var pool = allCells.filter { $0 != start && $0 != cookie }
            pool.shuffle(using: &rng)
            let obstacles = Array(pool.prefix(obstacleCount))

            if isSolvable(start: start, cookie: cookie, obstacles: Set(obstacles), gridSize: gridSize) {
                return LevelConfig(number: levelNumber, start: start, cookie: cookie, obstacles: obstacles)
            }
        }

        // Couldn't find a solvable obstacle layout after maxAttempts (very
        // unlikely on a 4x4 board with at most 4 rocks) - ship a rock-free
        // level rather than an unsolvable one.
        return LevelConfig(number: levelNumber, start: start, cookie: cookie, obstacles: [])
    }

    // MARK: - Helpers

    private static func manhattanDistance(_ a: GridPosition, _ b: GridPosition) -> Int {
        abs(a.col - b.col) + abs(a.row - b.row)
    }

    /// Breadth-first search from `start` to `cookie`, treating obstacles and
    /// the grid edge as walls - guarantees every generated level has at
    /// least one valid arrow-program solution.
    private static func isSolvable(start: GridPosition, cookie: GridPosition, obstacles: Set<GridPosition>, gridSize: Int) -> Bool {
        guard !obstacles.contains(start), !obstacles.contains(cookie) else { return false }

        var visited: Set<GridPosition> = [start]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            if current == cookie { return true }
            for direction in Direction.allCases {
                let next = current.applying(direction)
                guard next.isInBounds(gridSize: gridSize),
                      !obstacles.contains(next),
                      !visited.contains(next) else { continue }
                visited.insert(next)
                queue.append(next)
            }
        }
        return false
    }
}
