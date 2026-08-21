import SpriteKit

/// The named sub-nodes `DinoNode` needs to hold onto in order to animate the
/// character (swing a leg, widen the eye, etc). Everything else about the
/// shape is just fill-and-forget.
struct DinoShapeParts {
    /// Everything the dino is made of, grouped so squash/stretch/bounce can
    /// scale the whole character from one place.
    let root: SKNode
    let tail: SKShapeNode
    let frontLeg: SKShapeNode
    let backLeg: SKShapeNode
    let frontArm: SKShapeNode
    let backArm: SKShapeNode
    let head: SKNode
    let eyeWhite: SKShapeNode
}

/// Builds the chubby T-Rex shape **once**, entirely from `SKShapeNode`
/// primitives - no image assets. Every skin (see `DinoPalette`) calls this
/// exact same function; only the fill colors passed in change, so the
/// silhouette is guaranteed identical across skins.
///
/// Side-profile pose facing right by default (mirrored horizontally by
/// `DinoNode` when walking left) - upright stance, thick tail dragging low
/// behind for balance, big head with one visible eye, and comically tiny
/// arms up front.
enum DinoShapeBuilder {

    // MARK: - Tunables: proportions (fractions of one grid cell)

    static let bodyWidthFraction: CGFloat = 0.58
    static let bodyHeightFraction: CGFloat = 0.50
    static let headRadiusFraction: CGFloat = 0.25
    static let snoutRadiusFraction: CGFloat = 0.115
    static let nostrilRadiusFraction: CGFloat = 0.016
    static let eyeRadiusFraction: CGFloat = 0.058
    static let pupilRadiusFraction: CGFloat = 0.030
    static let highlightRadiusFraction: CGFloat = 0.012
    static let legWidthFraction: CGFloat = 0.15
    static let legHeightFraction: CGFloat = 0.24
    static let footWidthFraction: CGFloat = 0.19
    static let footHeightFraction: CGFloat = 0.075
    static let armWidthFraction: CGFloat = 0.06
    static let armHeightFraction: CGFloat = 0.11
    static let outlineWidth: CGFloat = 3

    static func build(cellSize: CGFloat, palette: DinoPalette) -> DinoShapeParts {
        let root = SKNode()

        let bodyWidth = cellSize * bodyWidthFraction
        let bodyHeight = cellSize * bodyHeightFraction
        // Body ellipse is centered a little above the node's own origin so
        // the legs (which hang below it) land close to y = 0 - that keeps
        // the character optically balanced on the grid tile.
        let bodyCenterY = cellSize * 0.06
        let bodyBottomY = bodyCenterY - bodyHeight * 0.5
        let bodyTopY = bodyCenterY + bodyHeight * 0.5

        let tail = makeTail(cellSize: cellSize, bodyWidth: bodyWidth, bodyBottomY: bodyBottomY, palette: palette)
        root.addChild(tail)

        let legHeight = cellSize * legHeightFraction
        let legWidth = cellSize * legWidthFraction
        let footSize = CGSize(width: cellSize * footWidthFraction, height: cellSize * footHeightFraction)
        let hipY = bodyBottomY + legHeight * 0.35
        let frontLeg = makeLeg(width: legWidth, height: legHeight, footSize: footSize, palette: palette)
        frontLeg.position = CGPoint(x: bodyWidth * 0.12, y: hipY)
        let backLeg = makeLeg(width: legWidth, height: legHeight, footSize: footSize, palette: palette)
        backLeg.position = CGPoint(x: -bodyWidth * 0.16, y: hipY)
        root.addChild(backLeg)
        root.addChild(frontLeg)

        let bodySize = CGSize(width: bodyWidth, height: bodyHeight)
        let body = SKShapeNode(ellipseOf: bodySize)
        body.position = CGPoint(x: 0, y: bodyCenterY)
        body.fillColor = palette.bodyColor
        body.strokeColor = palette.outlineColor
        body.lineWidth = outlineWidth
        root.addChild(body)

        let bellySize = CGSize(width: bodyWidth * 0.52, height: bodyHeight * 0.58)
        let belly = SKShapeNode(ellipseOf: bellySize)
        belly.fillColor = palette.bellyColor
        belly.strokeColor = .clear
        belly.position = CGPoint(x: bodyWidth * 0.04, y: bodyCenterY - bodyHeight * 0.08)
        root.addChild(belly)

        let armWidth = cellSize * armWidthFraction
        let armHeight = cellSize * armHeightFraction
        let armY = bodyCenterY + bodyHeight * 0.02
        let frontArm = makeArm(width: armWidth, height: armHeight, palette: palette)
        frontArm.position = CGPoint(x: bodyWidth * 0.30, y: armY)
        let backArm = makeArm(width: armWidth, height: armHeight, palette: palette)
        backArm.position = CGPoint(x: bodyWidth * 0.20, y: armY)
        root.addChild(backArm)
        root.addChild(frontArm)

        let head = makeHead(cellSize: cellSize, bodyWidth: bodyWidth, bodyTopY: bodyTopY, palette: palette)
        root.addChild(head.node)

        return DinoShapeParts(
            root: root,
            tail: tail,
            frontLeg: frontLeg,
            backLeg: backLeg,
            frontArm: frontArm,
            backArm: backArm,
            head: head.node,
            eyeWhite: head.eyeWhite
        )
    }

    // MARK: - Parts

    private static func makeTail(cellSize: CGFloat, bodyWidth: CGFloat, bodyBottomY: CGFloat, palette: DinoPalette) -> SKShapeNode {
        // Thick where it meets the body, tapering to a point that droops
        // down near the ground behind the character - a third contact
        // point, like a tripod, which is what makes an upright T-Rex read
        // as balanced rather than about to tip over backward.
        let baseX = -bodyWidth * 0.38
        let baseY = bodyBottomY + cellSize * 0.14
        let baseHalfWidth = cellSize * 0.11
        let tipX = -bodyWidth * 0.85
        let tipY = bodyBottomY - cellSize * 0.02

        let path = UIBezierPath()
        path.move(to: CGPoint(x: baseX, y: baseY + baseHalfWidth))
        path.addQuadCurve(
            to: CGPoint(x: tipX, y: tipY),
            controlPoint: CGPoint(x: baseX - cellSize * 0.30, y: baseY + baseHalfWidth * 0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: baseX, y: baseY - baseHalfWidth),
            controlPoint: CGPoint(x: baseX - cellSize * 0.22, y: tipY - cellSize * 0.03)
        )
        path.close()

        let tail = SKShapeNode(path: path.cgPath)
        tail.fillColor = palette.bodyColor
        tail.strokeColor = palette.outlineColor
        tail.lineWidth = outlineWidth
        return tail
    }

    private static func makeLeg(width: CGFloat, height: CGFloat, footSize: CGSize, palette: DinoPalette) -> SKShapeNode {
        // A pivot node at the hip, containing the visible capsule + foot, so
        // rotating the pivot swings the leg from the hip rather than its
        // own center.
        let pivot = SKShapeNode()

        let capsule = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: width / 2)
        capsule.position = CGPoint(x: 0, y: -height / 2)
        capsule.fillColor = palette.bodyColor
        capsule.strokeColor = palette.outlineColor
        capsule.lineWidth = outlineWidth * 0.8
        pivot.addChild(capsule)

        let foot = SKShapeNode(ellipseOf: footSize)
        foot.position = CGPoint(x: width * 0.08, y: -height + footSize.height * 0.3)
        foot.fillColor = palette.footColor
        foot.strokeColor = palette.outlineColor
        foot.lineWidth = outlineWidth * 0.7
        pivot.addChild(foot)

        return pivot
    }

    private static func makeArm(width: CGFloat, height: CGFloat, palette: DinoPalette) -> SKShapeNode {
        // Comically tiny capsule, pivoting from the shoulder - classic
        // T-Rex proportions played for laughs.
        let pivot = SKShapeNode()
        pivot.zRotation = -0.5

        let capsule = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: width / 2)
        capsule.position = CGPoint(x: 0, y: -height / 2)
        capsule.fillColor = palette.bodyColor
        capsule.strokeColor = palette.outlineColor
        capsule.lineWidth = outlineWidth * 0.6
        pivot.addChild(capsule)

        return pivot
    }

    private static func makeHead(cellSize: CGFloat, bodyWidth: CGFloat, bodyTopY: CGFloat, palette: DinoPalette) -> (node: SKNode, eyeWhite: SKShapeNode) {
        let head = SKNode()
        let headRadius = cellSize * headRadiusFraction
        // Overlaps the top-front of the body enough that there's no visible
        // neck gap - the head radius is deliberately generous for that.
        head.position = CGPoint(x: bodyWidth * 0.22, y: bodyTopY - headRadius * 0.35)

        let headShape = SKShapeNode(circleOfRadius: headRadius)
        headShape.fillColor = palette.bodyColor
        headShape.strokeColor = palette.outlineColor
        headShape.lineWidth = outlineWidth
        head.addChild(headShape)

        let snoutRadius = cellSize * snoutRadiusFraction
        let snout = SKShapeNode(circleOfRadius: snoutRadius)
        snout.fillColor = palette.snoutColor
        snout.strokeColor = palette.outlineColor
        snout.lineWidth = outlineWidth * 0.8
        snout.position = CGPoint(x: headRadius * 0.80, y: -headRadius * 0.20)
        head.addChild(snout)

        let nostril = SKShapeNode(circleOfRadius: cellSize * nostrilRadiusFraction)
        nostril.fillColor = palette.outlineColor
        nostril.strokeColor = .clear
        nostril.position = CGPoint(x: snoutRadius * 0.55, y: snoutRadius * 0.35)
        snout.addChild(nostril)

        // Only one eye: this is a side-profile character, so a second eye
        // on the far side would never be visible anyway.
        let eyeRadius = cellSize * eyeRadiusFraction
        let eyeWhite = SKShapeNode(circleOfRadius: eyeRadius)
        eyeWhite.fillColor = .white
        eyeWhite.strokeColor = palette.outlineColor
        eyeWhite.lineWidth = 1.5
        eyeWhite.position = CGPoint(x: headRadius * 0.30, y: headRadius * 0.30)
        head.addChild(eyeWhite)

        let pupil = SKShapeNode(circleOfRadius: cellSize * pupilRadiusFraction)
        pupil.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
        pupil.strokeColor = .clear
        pupil.position = CGPoint(x: eyeRadius * 0.30, y: 0)
        eyeWhite.addChild(pupil)

        let highlight = SKShapeNode(circleOfRadius: cellSize * highlightRadiusFraction)
        highlight.fillColor = .white
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: eyeRadius * 0.45, y: eyeRadius * 0.35)
        eyeWhite.addChild(highlight)

        return (head, eyeWhite)
    }
}
