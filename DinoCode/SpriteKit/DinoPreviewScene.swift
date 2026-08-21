import SpriteKit

/// A tiny, static SpriteKit scene that shows one skin's dino standing still
/// - used by the skin-picker swatches. Reuses `DinoNode`/`DinoShapeBuilder`
/// directly (the same geometry the in-game character uses), just with no
/// grid, no execution loop, and no animation running.
final class DinoPreviewScene: SKScene {

    init(palette: DinoPalette, size: CGSize) {
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .clear
        scaleMode = .aspectFit

        let cellSize = min(size.width, size.height) * 0.85
        let dino = DinoNode(cellSize: cellSize, palette: palette)
        // The character's own origin sits near its feet/mid-body rather
        // than its exact visual center, so nudge it down slightly to look
        // centered in the swatch frame.
        dino.position = CGPoint(x: -cellSize * 0.04, y: -cellSize * 0.12)
        addChild(dino)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
