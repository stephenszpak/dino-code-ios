import SpriteKit

/// Builds the static, non-animated parts of the scene: grid squares, grid
/// lines, the cookie, and any obstacle rocks. Kept separate from `GameScene`
/// so the "what does the board look like" code doesn't get tangled up with
/// "how does the dino move" code.
enum GridBuilder {

    // MARK: - Tunables

    static let tileFillColor = SKColor(red: 0.93, green: 0.87, blue: 0.70, alpha: 1.0)
    static let tileStrokeColor = SKColor(red: 0.78, green: 0.68, blue: 0.45, alpha: 1.0)
    static let tileStrokeWidth: CGFloat = 3
    static let tileCornerRadius: CGFloat = 10
    static let tileSpacing: CGFloat = 6

    static let cookieColor = SKColor(red: 0.80, green: 0.55, blue: 0.28, alpha: 1.0)
    static let cookieChipColor = SKColor(red: 0.40, green: 0.24, blue: 0.10, alpha: 1.0)

    static let obstacleColor = SKColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1.0)
    static let obstacleStrokeColor = SKColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1.0)

    /// Builds one square tile node, sized to fit `tileSize` with `tileSpacing`
    /// of gap baked in around it.
    static func makeTile(tileSize: CGFloat) -> SKShapeNode {
        let inset = tileSpacing / 2
        let rect = CGRect(x: -tileSize / 2 + inset, y: -tileSize / 2 + inset,
                           width: tileSize - tileSpacing, height: tileSize - tileSpacing)
        let node = SKShapeNode(rect: rect, cornerRadius: tileCornerRadius)
        node.fillColor = tileFillColor
        node.strokeColor = tileStrokeColor
        node.lineWidth = tileStrokeWidth
        return node
    }

    /// A simple round cookie with chocolate-chip dots, built entirely from
    /// shape primitives.
    static func makeCookie(radius: CGFloat) -> SKNode {
        let container = SKNode()
        container.name = "cookie"

        let base = SKShapeNode(circleOfRadius: radius)
        base.fillColor = cookieColor
        base.strokeColor = cookieChipColor.withAlphaComponent(0.4)
        base.lineWidth = 2
        container.addChild(base)

        let chipOffsets: [(CGFloat, CGFloat)] = [
            (-0.4, 0.35), (0.3, 0.4), (0.0, -0.1), (-0.35, -0.3), (0.4, -0.25)
        ]
        for (dx, dy) in chipOffsets {
            let chip = SKShapeNode(circleOfRadius: radius * 0.14)
            chip.position = CGPoint(x: dx * radius, y: dy * radius)
            chip.fillColor = cookieChipColor
            chip.strokeColor = .clear
            container.addChild(chip)
        }
        return container
    }

    /// A rounded rock obstacle.
    static func makeObstacle(size: CGFloat) -> SKNode {
        let container = SKNode()
        container.name = "obstacle"

        let rock = SKShapeNode(ellipseOf: CGSize(width: size, height: size * 0.8))
        rock.fillColor = obstacleColor
        rock.strokeColor = obstacleStrokeColor
        rock.lineWidth = 3
        container.addChild(rock)

        let highlight = SKShapeNode(ellipseOf: CGSize(width: size * 0.35, height: size * 0.22))
        highlight.position = CGPoint(x: -size * 0.15, y: size * 0.12)
        highlight.fillColor = obstacleStrokeColor.withAlphaComponent(0.25)
        highlight.strokeColor = .clear
        container.addChild(highlight)

        return container
    }
}
