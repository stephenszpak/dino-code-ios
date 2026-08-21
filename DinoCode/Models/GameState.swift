import Foundation
import Combine

/// What happened the last time the dino's program ran.
enum RunResult: Equatable {
    case success
    /// Program stopped early because step `stepIndex` walked into a wall or obstacle.
    case failed(stepIndex: Int)
    /// Every step ran without hitting a wall, but the dino never reached the cookie.
    case incomplete
}

/// ============================================================================
/// SwiftUI <-> SpriteKit communication hub.
///
/// This single `ObservableObject` is the shared source of truth for the whole
/// app. SwiftUI views (`ContentView` and friends) read `@Published` properties
/// to draw the program strip, disable buttons while the dino is moving, etc.,
/// and call methods here (`addStep`, `play`, `clearProgram`) in response to
/// taps. `GameScene` (SpriteKit) holds a reference to this *same* instance and
/// subscribes to the two "trigger" properties (`playToken`, `resetToken`) with
/// Combine to know when to animate. GameScene also writes back into this
/// object (`isExecuting`, `activeStepIndex`, `lastResult`) so SwiftUI can
/// reflect what's happening on screen (e.g. highlight the step currently
/// running, or show a "yay!" banner).
///
/// Neither side ever touches the other's UI objects directly - they only ever
/// read/write this shared state. That's the whole trick.
/// ============================================================================
final class GameState: ObservableObject {

    // MARK: - Tunable constants

    static let gridSize = Levels.gridSize
    static let maxProgramLength = 12

    // MARK: - Skin

    /// Which color skin the dino wears. Chosen on the skin-picker screen
    /// shown before the first level; can be reopened later via
    /// `openSkinPicker()`.
    @Published private(set) var selectedPalette: DinoPalette = DinoSkins.all[0]

    /// Whether the skin-picker screen should be shown instead of the game.
    /// Starts `true` so a kid picks a skin before playing.
    @Published var isPickingSkin: Bool = true

    // MARK: - Level

    @Published var level: Int = 1

    var levelConfig: LevelConfig { Levels.config(for: level) }

    /// Whether there's a level after this one to advance to (used to decide
    /// whether PLAY should turn into a NEXT LEVEL button after a win).
    var hasNextLevel: Bool { level < Levels.totalLevels }

    // MARK: - Program (the "code" the kid has written)

    @Published private(set) var program: [Direction] = []

    // MARK: - Execution state (driven by GameScene while the program plays)

    /// True from the moment PLAY starts until the dino finishes its run.
    /// SwiftUI uses this to grey out the arrow/clear/undo buttons.
    @Published var isExecuting: Bool = false

    /// Index into `program` of the step currently animating, so the program
    /// strip can highlight it. `nil` when not executing.
    @Published var activeStepIndex: Int? = nil

    /// Outcome of the most recently completed run, for showing a banner.
    @Published var lastResult: RunResult? = nil

    // MARK: - Triggers
    //
    // GameScene doesn't have a natural place to "poll" SwiftUI, so instead we
    // use two simple incrementing counters as one-shot signals. SwiftUI never
    // reads these; GameScene subscribes to them with Combine (`sink`) and
    // reacts whenever the value changes, ignoring the value itself.

    /// Bumped whenever PLAY is tapped - tells GameScene "run the program now".
    @Published private(set) var playToken: Int = 0

    /// Bumped whenever the scene should reset the dino to the level's start
    /// square (on CLEAR, or when switching levels).
    @Published private(set) var resetToken: Int = 0

    // MARK: - Intents (called from SwiftUI button actions)

    /// Called from the skin-picker screen. Dismisses the picker and, if a
    /// board is already showing, tells `GameScene` to rebuild the dino in
    /// its new colors via the same `resetToken` signal used by CLEAR.
    func selectSkin(_ palette: DinoPalette) {
        selectedPalette = palette
        isPickingSkin = false
        resetToken += 1
    }

    /// Reopens the skin picker without losing level progress.
    func openSkinPicker() {
        guard !isExecuting else { return }
        isPickingSkin = true
    }

    func addStep(_ direction: Direction) {
        guard !isExecuting, program.count < Self.maxProgramLength else { return }
        program.append(direction)
    }

    func removeLastStep() {
        guard !isExecuting, !program.isEmpty else { return }
        program.removeLast()
    }

    func clearProgram() {
        guard !isExecuting else { return }
        program.removeAll()
        lastResult = nil
        activeStepIndex = nil
        resetToken += 1
    }

    func play() {
        guard !isExecuting, !program.isEmpty else { return }
        lastResult = nil
        playToken += 1
    }

    func selectLevel(_ number: Int) {
        guard !isExecuting, number != level, (1...Levels.totalLevels).contains(number) else { return }
        level = number
        program.removeAll()
        lastResult = nil
        activeStepIndex = nil
        resetToken += 1
    }

    /// Called from the NEXT LEVEL button that replaces PLAY after a win.
    func advanceToNextLevel() {
        guard hasNextLevel else { return }
        selectLevel(level + 1)
    }

    // MARK: - Callbacks from GameScene (execution progress)

    /// GameScene calls this right before animating step `index`.
    func beginExecution() {
        isExecuting = true
        activeStepIndex = nil
        lastResult = nil
    }

    func reportStepStarted(_ index: Int) {
        activeStepIndex = index
    }

    func finishExecution(result: RunResult) {
        isExecuting = false
        lastResult = result
        // Keep the failing step highlighted in the strip so the kid can see
        // exactly which instruction was the problem; clear it otherwise.
        if case .failed(let stepIndex) = result {
            activeStepIndex = stepIndex
        } else {
            activeStepIndex = nil
        }
    }
}
