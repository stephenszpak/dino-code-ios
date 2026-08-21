import SwiftUI

/// Shows the sequence of arrow taps the kid has queued up - the "program".
/// The step currently animating (while PLAY is running) is highlighted, and
/// the step that caused a bonk stays highlighted in red after execution
/// stops, so the kid can see exactly which instruction was the problem.
struct ProgramStripView: View {
    @ObservedObject var gameState: GameState

    static let chipSize: CGFloat = 52
    static let spacing: CGFloat = 8

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.spacing) {
                if gameState.program.isEmpty {
                    Text("Tap the arrows to build a program")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                } else {
                    ForEach(Array(gameState.program.enumerated()), id: \.offset) { index, direction in
                        chip(for: direction, at: index)
                    }
                }
            }
            .padding(.horizontal, 10)
            .frame(minHeight: Self.chipSize + 8)
        }
        .frame(height: Self.chipSize + 16)
        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func chip(for direction: Direction, at index: Int) -> some View {
        let isActive = gameState.activeStepIndex == index
        let isFailedStep: Bool = {
            if case .failed(let stepIndex) = gameState.lastResult { return stepIndex == index }
            return false
        }()

        return Image(systemName: direction.symbolName)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: Self.chipSize, height: Self.chipSize)
            .background(chipColor(isActive: isActive, isFailed: isFailedStep), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(isActive ? 1.12 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    private func chipColor(isActive: Bool, isFailed: Bool) -> Color {
        if isFailed { return .dinoRed }
        if isActive { return .dinoYellow }
        return .dinoBlue
    }
}
