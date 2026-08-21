import Foundation

/// Static description of one level: where the dino starts, where the cookie
/// is, and which squares (if any) are blocked. Grid is always 4x4.
struct LevelConfig {
    let number: Int
    let start: GridPosition
    let cookie: GridPosition
    let obstacles: [GridPosition]

    /// A short, kid-facing name shown on the level selector.
    var title: String { "Level \(number)" }
}

enum Levels {
    static let gridSize = 4

    /// Level 1: cookie is close by in a straight line - two taps of the same arrow.
    static let level1 = LevelConfig(
        number: 1,
        start: GridPosition(col: 0, row: 0),
        cookie: GridPosition(col: 2, row: 0),
        obstacles: []
    )

    /// Level 2: cookie is across the grid - needs two different directions combined.
    static let level2 = LevelConfig(
        number: 2,
        start: GridPosition(col: 0, row: 0),
        cookie: GridPosition(col: 3, row: 3),
        obstacles: []
    )

    /// Level 3: a rock blocks the direct path, so the straight-line program
    /// bonks into it - the kid has to route the dino around.
    static let level3 = LevelConfig(
        number: 3,
        start: GridPosition(col: 0, row: 0),
        cookie: GridPosition(col: 3, row: 0),
        obstacles: [GridPosition(col: 1, row: 0)]
    )

    /// The 3 hand-designed introductory levels.
    static let handcrafted: [LevelConfig] = [level1, level2, level3]

    /// How many procedurally generated levels follow the handcrafted ones.
    static let generatedCount = 10

    /// Total number of levels shown in the level selector.
    static let totalLevels = handcrafted.count + generatedCount

    /// Returns the config for any level number from 1...`totalLevels`.
    /// Levels 1-3 are the hand-designed ones above; everything past that is
    /// procedurally generated (see `RandomLevelGenerator`) - each level
    /// number is its own random seed, so a given level's map is stable for
    /// the whole app session.
    static func config(for levelNumber: Int) -> LevelConfig {
        if levelNumber <= handcrafted.count {
            return handcrafted[levelNumber - 1]
        }
        return RandomLevelGenerator.generate(levelNumber: levelNumber, gridSize: gridSize)
    }
}
