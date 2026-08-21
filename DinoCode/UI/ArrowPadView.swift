import SwiftUI

/// The up/down/left/right D-pad. Each tap *queues* a step onto the program
/// strip via `gameState.addStep` - it does not move the dino immediately.
struct ArrowPadView: View {
    @ObservedObject var gameState: GameState

    static let buttonSize: CGFloat = 84
    static let spacing: CGFloat = 10

    var body: some View {
        VStack(spacing: Self.spacing) {
            arrowButton(.up)
            HStack(spacing: Self.spacing) {
                arrowButton(.left)
                Color.clear.frame(width: Self.buttonSize, height: Self.buttonSize)
                arrowButton(.right)
            }
            arrowButton(.down)
        }
    }

    private func arrowButton(_ direction: Direction) -> some View {
        Button {
            gameState.addStep(direction)
            SoundGenerator.shared.playTapSound()
        } label: {
            Image(systemName: direction.symbolName)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .background(Color.dinoBlue, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(gameState.isExecuting || gameState.program.count >= GameState.maxProgramLength)
        .opacity(gameState.isExecuting ? 0.5 : 1.0)
    }
}

extension Color {
    static let dinoBlue = Color(red: 0.20, green: 0.47, blue: 0.78)
    static let dinoGreen = Color(red: 0.30, green: 0.68, blue: 0.35)
    static let dinoRed = Color(red: 0.85, green: 0.30, blue: 0.28)
    static let dinoYellow = Color(red: 0.95, green: 0.73, blue: 0.20)
}
