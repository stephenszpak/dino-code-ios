import SpriteKit
import Combine

/// ============================================================================
/// The SpriteKit half of the SwiftUI <-> SpriteKit bridge.
///
/// `GameScene` is handed the *same* `GameState` instance that SwiftUI's
/// `ContentView` owns (see `ContentView.init`). It never gets or sets SwiftUI
/// view state directly - instead:
///
///   - It subscribes (via Combine, in `subscribeToGameState`) to
///     `gameState.$playToken` and `gameState.$resetToken`. Those are simple
///     counters that SwiftUI bumps when the kid taps PLAY or CLEAR. The
///     *value* doesn't matter, only that it changed - that's the signal to
///     run the program or rebuild the board.
///   - While running, it calls back into `gameState` (`beginExecution`,
///     `reportStepStarted`, `finishExecution`) so SwiftUI can grey out
///     buttons and highlight the step currently animating in the program
///     strip.
///
/// This is the standard "one shared ObservableObject, SwiftUI drives it with
/// property changes, SpriteKit reacts with Combine" pattern for bridging the
/// two frameworks.
/// ============================================================================
final class GameScene: SKScene {

    // MARK: - Tunables

    static let backgroundColorValue = SKColor(red: 0.55, green: 0.78, blue: 0.90, alpha: 1.0)
    static let sceneEdgePadding: CGFloat = 40

    private let gameState: GameState
    private var cancellables = Set<AnyCancellable>()

    private var tileSize: CGFloat = 0
    private var boardOrigin: CGPoint = .zero // center of grid cell (0,0)

    private var boardLayer = SKNode()
    private var dinoNode: DinoNode!
    private var dinoGridPosition = GridPosition(col: 0, row: 0)

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: CGSize(width: 1000, height: 1000))
        scaleMode = .aspectFit
        backgroundColor = Self.backgroundColorValue
        // Center the coordinate system on the scene's middle instead of the
        // default bottom-left corner, so `point(for:)` below can place grid
        // tiles symmetrically around (0,0).
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// `didMove(to:)` can fire more than once for the same scene instance -
    /// e.g. toggling the skin picker removes the `SpriteView` from the
    /// SwiftUI hierarchy and later re-adds it, wrapping this *same*
    /// `GameScene` in a brand-new `SKView`. Guard one-time setup so we don't
    /// try to re-add `boardLayer` (which SpriteKit rejects since it already
    /// has a parent) or stack duplicate Combine subscriptions.
    private var hasFinishedInitialSetup = false

    override func didMove(to view: SKView) {
        guard !hasFinishedInitialSetup else { return }
        hasFinishedInitialSetup = true
        addChild(boardLayer)
        buildBoard()
        subscribeToGameState()
    }

    // MARK: - Combine bridge

    private func subscribeToGameState() {
        // dropFirst() so the initial published value (0) doesn't fire an
        // action the moment we subscribe.
        gameState.$playToken
            .dropFirst()
            .sink { [weak self] _ in self?.runProgram() }
            .store(in: &cancellables)

        gameState.$resetToken
            .dropFirst()
            .sink { [weak self] _ in self?.buildBoard() }
            .store(in: &cancellables)
    }

    // MARK: - Board construction

    /// (Re)builds the grid, cookie, and obstacles for the current level, and
    /// snaps the dino back to the level's start square. Called on first
    /// appearance, and again whenever CLEAR is tapped or the level changes.
    private func buildBoard() {
        boardLayer.removeAllChildren()

        let config = gameState.levelConfig
        let gridSize = GameState.gridSize
        let boardExtent = min(size.width, size.height) - Self.sceneEdgePadding * 2
        tileSize = boardExtent / CGFloat(gridSize)
        let boardOriginOffset = -boardExtent / 2 + tileSize / 2
        boardOrigin = CGPoint(x: boardOriginOffset, y: boardOriginOffset)

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let tile = GridBuilder.makeTile(tileSize: tileSize)
                tile.position = point(for: GridPosition(col: col, row: row))
                boardLayer.addChild(tile)
            }
        }

        let cookie = GridBuilder.makeCookie(radius: tileSize * 0.28)
        cookie.position = point(for: config.cookie)
        boardLayer.addChild(cookie)

        for obstacle in config.obstacles {
            let rock = GridBuilder.makeObstacle(size: tileSize * 0.55)
            rock.position = point(for: obstacle)
            boardLayer.addChild(rock)
        }

        dinoNode = DinoNode(cellSize: tileSize, palette: gameState.selectedPalette)
        dinoGridPosition = config.start
        dinoNode.position = point(for: config.start)
        boardLayer.addChild(dinoNode)
    }

    private func point(for gridPos: GridPosition) -> CGPoint {
        CGPoint(
            x: boardOrigin.x + CGFloat(gridPos.col) * tileSize,
            y: boardOrigin.y + CGFloat(gridPos.row) * tileSize
        )
    }

    // MARK: - Program execution

    private func runProgram() {
        guard !gameState.program.isEmpty else { return }
        gameState.beginExecution()
        dinoNode.resetPose()
        dinoGridPosition = gameState.levelConfig.start
        dinoNode.position = point(for: dinoGridPosition)
        executeStep(index: 0)
    }

    private func executeStep(index: Int) {
        let program = gameState.program
        guard index < program.count else {
            gameState.finishExecution(result: .incomplete)
            return
        }

        let direction = program[index]
        let targetPos = dinoGridPosition.applying(direction)
        gameState.reportStepStarted(index)

        let config = gameState.levelConfig
        let isBlocked = !targetPos.isInBounds(gridSize: GameState.gridSize)
            || config.obstacles.contains(targetPos)

        if isBlocked {
            SoundGenerator.shared.playBonkSound()
            dinoNode.playBonk { [weak self] in
                guard let self else { return }
                HapticsManager.error()
                self.gameState.finishExecution(result: .failed(stepIndex: index))
            }
            return
        }

        dinoGridPosition = targetPos
        let destination = point(for: targetPos)
        SoundGenerator.shared.playStepSound()
        dinoNode.playStep(to: destination, duration: DinoNode.stepDuration) { [weak self] in
            guard let self else { return }
            if targetPos == config.cookie {
                self.dinoNode.playCelebrate()
                self.spawnConfetti(at: destination)
                SoundGenerator.shared.playWinSound()
                HapticsManager.success()
                self.gameState.finishExecution(result: .success)
            } else {
                self.executeStep(index: index + 1)
            }
        }
    }

    // MARK: - Celebration

    private func spawnConfetti(at point: CGPoint) {
        let confetti = ConfettiFactory.makeConfetti()
        confetti.position = point
        boardLayer.addChild(confetti)
        confetti.run(.sequence([
            .wait(forDuration: 1.2),
            .removeFromParent(),
        ]))
    }
}
