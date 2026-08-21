import SwiftUI
import SpriteKit

/// Root layout: the SpriteKit board on the left, controls on the right.
///
/// ## The SwiftUI <-> SpriteKit bridge, concretely
///
/// `gameState` and `scene` are created together in `init()` from the *same*
/// local `GameState` instance, so both `ContentView` (via `@StateObject`)
/// and `GameScene` (via a plain stored reference) end up pointing at one
/// shared object. From then on:
///   - Buttons here call methods on `gameState` (e.g. `gameState.play()`).
///   - `GameScene` observes `gameState`'s `@Published` properties with
///     Combine and animates in response (see `GameScene.subscribeToGameState`).
///   - `GameScene` calls back into `gameState` as it animates, and SwiftUI
///     re-renders automatically because `gameState` is `@ObservedObject`/
///     `@StateObject` - that's the whole bridge, no delegates needed.
struct ContentView: View {
    @StateObject private var gameState: GameState
    @State private var scene: GameScene

    init() {
        let state = GameState()
        _gameState = StateObject(wrappedValue: state)
        _scene = State(initialValue: GameScene(gameState: state))
    }

    var body: some View {
        // The skin picker is a full-screen step shown before play (and
        // reachable again from the palette button below), swapped in ahead
        // of the normal board+controls layout.
        if gameState.isPickingSkin {
            SkinPickerView(gameState: gameState)
        } else {
            HStack(spacing: 24) {
                boardPane
                controlsPane
            }
            .padding(24)
            .background(Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea())
        }
    }

    private var boardPane: some View {
        SpriteView(scene: scene)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private var controlsPane: some View {
        VStack(spacing: 20) {
            HStack {
                // Fixed width so the (now scrollable, 13-level) selector
                // doesn't compete with the Spacer for space and push the
                // result banner out of the trailing corner.
                LevelSelectorView(gameState: gameState)
                    .frame(maxWidth: 210)
                skinButton
                Spacer()
                resultBanner
            }

            Spacer(minLength: 0)

            ArrowPadView(gameState: gameState)

            Spacer(minLength: 0)

            ProgramStripView(gameState: gameState)

            ControlButtonsView(gameState: gameState)
        }
        .frame(width: 380)
    }

    /// Reopens the skin picker without losing level progress.
    private var skinButton: some View {
        Button {
            gameState.openSkinPicker()
        } label: {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.dinoBlue, in: Circle())
        }
        .disabled(gameState.isExecuting)
        .opacity(gameState.isExecuting ? 0.4 : 1.0)
    }

    @ViewBuilder
    private var resultBanner: some View {
        switch gameState.lastResult {
        case .success:
            bannerLabel("Yay! 🍪", color: .dinoGreen)
        case .failed:
            bannerLabel("Oops, try again!", color: .dinoRed)
        case .incomplete, .none:
            EmptyView()
        }
    }

    private func bannerLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color, in: Capsule())
    }
}

#Preview {
    ContentView()
}
