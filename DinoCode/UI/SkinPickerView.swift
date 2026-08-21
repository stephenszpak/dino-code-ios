import SwiftUI
import SpriteKit

/// Full-screen "choose your dino" step shown before the first level (and
/// reachable again later via a button near the level selector). Tapping a
/// card both picks the skin and dismisses the picker - one big kid-friendly
/// tap, no separate confirm step.
struct SkinPickerView: View {
    @ObservedObject var gameState: GameState

    /// Built once (in `init`, mirroring the `GameState`/`GameScene` pairing
    /// trick in `ContentView`) so re-renders of this view - e.g. the
    /// selection border animating - don't keep rebuilding SpriteKit scenes.
    @State private var previewScenes: [String: SKScene]

    static let swatchSize: CGFloat = 220

    init(gameState: GameState) {
        self.gameState = gameState
        var scenes: [String: SKScene] = [:]
        for palette in DinoSkins.all {
            scenes[palette.id] = DinoPreviewScene(
                palette: palette,
                size: CGSize(width: Self.swatchSize, height: Self.swatchSize)
            )
        }
        _previewScenes = State(initialValue: scenes)
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Choose Your Dino!")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dinoBlue)

            HStack(spacing: 28) {
                ForEach(DinoSkins.all) { palette in
                    swatchCard(palette)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea())
    }

    private func swatchCard(_ palette: DinoPalette) -> some View {
        let isSelected = gameState.selectedPalette == palette
        return Button {
            gameState.selectSkin(palette)
        } label: {
            VStack(spacing: 16) {
                if let scene = previewScenes[palette.id] {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .frame(width: Self.swatchSize, height: Self.swatchSize)
                }
                Text(palette.displayName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinoBlue)
            }
            .padding(20)
            .frame(width: 280, height: 340)
            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(isSelected ? Color.dinoGreen : Color.clear, lineWidth: 5)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}
