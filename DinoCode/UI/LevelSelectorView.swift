import SwiftUI

/// Numbered level picker. Levels 1-3 are hand-designed; everything after
/// that is procedurally generated on the fly (see `RandomLevelGenerator`),
/// so this view only needs level *numbers*, not their `LevelConfig`s -
/// generating a config just to read its number would build all 10 random
/// maps up front for no reason.
///
/// Scrollable since `Levels.totalLevels` (13) is too many numbered circles
/// to fit in the controls column at once; auto-scrolls to the current level
/// whenever it changes (e.g. via NEXT LEVEL) so the selection stays visible.
struct LevelSelectorView: View {
    @ObservedObject var gameState: GameState

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(1...Levels.totalLevels, id: \.self) { number in
                        levelButton(number)
                            .id(number)
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: gameState.level) { _, newLevel in
                withAnimation {
                    proxy.scrollTo(newLevel, anchor: .center)
                }
            }
        }
        .frame(height: 60)
    }

    private func levelButton(_ number: Int) -> some View {
        let isSelected = gameState.level == number
        return Button {
            gameState.selectLevel(number)
        } label: {
            Text("\(number)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(isSelected ? .white : Color.dinoBlue)
                .frame(width: 48, height: 48)
                .background(Circle().fill(isSelected ? Color.dinoBlue : Color.white.opacity(0.7)))
                .overlay(Circle().stroke(Color.dinoBlue, lineWidth: 2))
        }
        .disabled(gameState.isExecuting)
    }
}
