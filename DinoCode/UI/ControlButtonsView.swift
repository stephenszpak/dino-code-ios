import SwiftUI

/// PLAY (green, runs the program), CLEAR (red, wipes program + resets dino),
/// and a small undo button for backing out a single mis-tapped arrow.
///
/// After a successful run, PLAY is swapped out for a NEXT LEVEL button (as
/// long as there's a level after this one) so a kid who just won doesn't
/// have to hunt for the level selector - the natural next tap keeps them
/// moving forward.
struct ControlButtonsView: View {
    @ObservedObject var gameState: GameState

    private var showNextLevelButton: Bool {
        gameState.lastResult == .success && gameState.hasNextLevel
    }

    var body: some View {
        HStack(spacing: 14) {
            undoButton
            clearButton
            if showNextLevelButton {
                nextLevelButton
            } else {
                playButton
            }
        }
    }

    private var undoButton: some View {
        Button {
            gameState.removeLastStep()
        } label: {
            Image(systemName: "delete.left.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Color.gray.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(gameState.isExecuting || gameState.program.isEmpty)
        .opacity((gameState.isExecuting || gameState.program.isEmpty) ? 0.4 : 1.0)
    }

    private var clearButton: some View {
        Button {
            gameState.clearProgram()
        } label: {
            Label("Clear", systemImage: "xmark.circle.fill")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 150, height: 64)
                .background(Color.dinoRed, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(gameState.isExecuting)
        .opacity(gameState.isExecuting ? 0.5 : 1.0)
    }

    private var playButton: some View {
        Button {
            gameState.play()
        } label: {
            Label("Play", systemImage: "play.fill")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 170, height: 72)
                .background(Color.dinoGreen, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(gameState.isExecuting || gameState.program.isEmpty)
        .opacity((gameState.isExecuting || gameState.program.isEmpty) ? 0.5 : 1.0)
    }

    private var nextLevelButton: some View {
        Button {
            gameState.advanceToNextLevel()
        } label: {
            Label("Next Level", systemImage: "arrow.right.circle.fill")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 170, height: 72)
                .background(Color.dinoYellow, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(gameState.isExecuting)
    }
}
