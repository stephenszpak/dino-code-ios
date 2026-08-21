import SpriteKit

/// The dino character. `GameScene` only ever talks to this node through the
/// four methods below (`playStep`, `playBonk`, `playCelebrate`, `resetPose`)
/// so the shape and skin can be changed freely without touching scene or
/// execution logic. The shape itself lives in `DinoShapeBuilder` - this file
/// is just animation, driven by the named parts that builder hands back.
final class DinoNode: SKNode {

    // MARK: - Tunables: animation

    static let stepDuration: TimeInterval = 1.0
    static let legSwingAngle: CGFloat = 0.5
    static let legSwingCycleDuration: TimeInterval = 0.25
    static let armSwingAngle: CGFloat = 0.18
    static let landingBounceScale: CGFloat = 1.16
    static let landingBounceDuration: TimeInterval = 0.18
    static let bonkShrugDuration: TimeInterval = 0.16
    static let bonkEyeWidenScale: CGFloat = 1.3
    static let celebrateHopHeightFraction: CGFloat = 0.22
    static let celebrateHopDuration: TimeInterval = 0.18
    static let celebrateHopCount = 3
    static let celebrateEyeWidenScale: CGFloat = 1.4

    let palette: DinoPalette
    private let cellSize: CGFloat
    private let parts: DinoShapeParts

    init(cellSize: CGFloat, palette: DinoPalette) {
        self.cellSize = cellSize
        self.palette = palette
        self.parts = DinoShapeBuilder.build(cellSize: cellSize, palette: palette)
        super.init()
        addChild(parts.root)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Public animation API (called by GameScene)

    /// Move one grid cell over `duration`: legs and arms swing while
    /// walking, then a squash-and-stretch bounce plays on landing. Calls
    /// `completion` once the landing bounce finishes.
    func playStep(to point: CGPoint, duration: TimeInterval, completion: @escaping () -> Void) {
        faceDirection(dx: point.x - position.x)

        let move = SKAction.move(to: point, duration: duration)
        move.timingMode = .easeInEaseOut
        run(move)

        let cycles = max(Int(duration / Self.legSwingCycleDuration), 1)
        startWalkCycle(cycles: cycles)

        run(.sequence([.wait(forDuration: duration), squashAndStretch()])) {
            completion()
        }
    }

    /// Surprised shrug when the dino walks into a wall/obstacle: a quick
    /// recoil, eye goes wide, then settles back into a droopy pose.
    func playBonk(completion: @escaping () -> Void) {
        let eyeWiden = SKAction.scale(to: Self.bonkEyeWidenScale, duration: Self.bonkShrugDuration)
        let eyeSettle = SKAction.scale(to: 1.0, duration: Self.bonkShrugDuration * 1.5)
        parts.eyeWhite.run(.sequence([eyeWiden, eyeSettle]))

        let recoilAngle: CGFloat = 0.12
        let headDroop = SKAction.sequence([
            .rotate(byAngle: -recoilAngle, duration: Self.bonkShrugDuration),
            .rotate(byAngle: recoilAngle * 1.4, duration: Self.bonkShrugDuration * 1.5),
            .rotate(byAngle: -recoilAngle * 0.4, duration: Self.bonkShrugDuration),
        ])
        parts.head.run(headDroop)

        let shrink = SKAction.scale(to: 0.88, duration: Self.bonkShrugDuration)
        let wiggle = SKAction.sequence([
            .rotate(byAngle: -0.12, duration: Self.bonkShrugDuration * 0.6),
            .rotate(byAngle: 0.22, duration: Self.bonkShrugDuration * 1.2),
            .rotate(byAngle: -0.10, duration: Self.bonkShrugDuration * 0.6),
        ])
        let back = SKAction.scale(to: 1.0, duration: Self.bonkShrugDuration)
        parts.root.run(.sequence([.group([shrink, wiggle]), back])) { completion() }
    }

    /// Happy dance on reaching the cookie: wide eye, a few hops with tiny
    /// arms waving, and a spin.
    func playCelebrate() {
        parts.eyeWhite.run(.scale(to: Self.celebrateEyeWidenScale, duration: 0.15))

        let hopHeight = cellSize * Self.celebrateHopHeightFraction
        let up = SKAction.moveBy(x: 0, y: hopHeight, duration: Self.celebrateHopDuration)
        up.timingMode = .easeOut
        let down = SKAction.moveBy(x: 0, y: -hopHeight, duration: Self.celebrateHopDuration)
        down.timingMode = .easeIn
        let hop = SKAction.sequence([up, down])

        let armWave = SKAction.sequence([
            .rotate(byAngle: 0.5, duration: Self.celebrateHopDuration / 2),
            .rotate(byAngle: -0.5, duration: Self.celebrateHopDuration / 2),
        ])
        [parts.frontArm, parts.backArm].forEach { $0.run(.repeat(armWave, count: Self.celebrateHopCount)) }

        let legKick = SKAction.sequence([
            .rotate(toAngle: 0.4, duration: Self.celebrateHopDuration / 2, shortestUnitArc: true),
            .rotate(toAngle: -0.4, duration: Self.celebrateHopDuration / 2, shortestUnitArc: true),
        ])
        [parts.frontLeg, parts.backLeg].forEach { $0.run(.repeat(legKick, count: Self.celebrateHopCount)) }

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.6)
        run(.sequence([.repeat(hop, count: Self.celebrateHopCount), spin]))
    }

    /// Snap back to a neutral standing pose (used when the board resets).
    func resetPose() {
        removeAllActions()
        parts.root.removeAllActions()
        parts.head.removeAllActions()
        [parts.frontLeg, parts.backLeg, parts.frontArm, parts.backArm].forEach {
            $0.removeAllActions()
            $0.zRotation = 0
        }
        parts.eyeWhite.removeAllActions()
        parts.eyeWhite.setScale(1.0)
        setScale(1.0)
        parts.root.setScale(1.0)
        parts.root.zRotation = 0
        parts.head.zRotation = 0
        zRotation = 0
        xScale = abs(xScale)
    }

    // MARK: - Helpers

    private func faceDirection(dx: CGFloat) {
        guard abs(dx) > 0.01 else { return }
        let shouldFaceRight = dx > 0
        let targetXScale: CGFloat = shouldFaceRight ? abs(xScale) : -abs(xScale)
        xScale = targetXScale == 0 ? (shouldFaceRight ? 1 : -1) : targetXScale
    }

    /// Legs swing opposite each other (front forward while back swings
    /// back, and vice versa) and the tiny arms bob along with them, all
    /// repeated for the whole step duration.
    private func startWalkCycle(cycles: Int) {
        let legForward = SKAction.rotate(toAngle: Self.legSwingAngle, duration: Self.legSwingCycleDuration / 2, shortestUnitArc: true)
        let legBackward = SKAction.rotate(toAngle: -Self.legSwingAngle, duration: Self.legSwingCycleDuration / 2, shortestUnitArc: true)
        let legFrontCycle = SKAction.repeat(.sequence([legForward, legBackward]), count: cycles)
        let legBackCycle = SKAction.repeat(.sequence([legBackward, legForward]), count: cycles)
        let legReset = SKAction.rotate(toAngle: 0, duration: Self.legSwingCycleDuration / 2)

        parts.frontLeg.run(.sequence([legFrontCycle, legReset]))
        parts.backLeg.run(.sequence([legBackCycle, legReset]))

        let armBaseAngle = parts.frontArm.zRotation
        let armForward = SKAction.rotate(toAngle: armBaseAngle + Self.armSwingAngle, duration: Self.legSwingCycleDuration / 2, shortestUnitArc: true)
        let armBackward = SKAction.rotate(toAngle: armBaseAngle - Self.armSwingAngle, duration: Self.legSwingCycleDuration / 2, shortestUnitArc: true)
        let armCycle = SKAction.repeat(.sequence([armForward, armBackward]), count: cycles)
        let armReset = SKAction.rotate(toAngle: armBaseAngle, duration: Self.legSwingCycleDuration / 2)

        parts.frontArm.run(.sequence([armCycle, armReset]))
        parts.backArm.run(.sequence([armCycle, armReset]))
    }

    private func squashAndStretch() -> SKAction {
        let squash = SKAction.scaleX(to: 1.22, y: 0.82, duration: Self.landingBounceDuration / 2)
        let stretch = SKAction.scaleX(to: 0.92, y: Self.landingBounceScale, duration: Self.landingBounceDuration / 2)
        let settle = SKAction.scale(to: 1.0, duration: Self.landingBounceDuration / 2)
        return .sequence([squash, stretch, settle])
    }
}
