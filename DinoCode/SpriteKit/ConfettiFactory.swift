import SpriteKit

/// Builds the win-celebration confetti burst. Uses `SKEmitterNode` with a
/// tiny particle texture generated in code (a filled square, rasterized via
/// `SKView.texture(from:)`) so there's no image asset to ship - just like
/// the dinosaur, the confetti is "drawn" by code.
enum ConfettiFactory {

    // MARK: - Tunables

    static let colors: [SKColor] = [
        .dinoConfettiPink, .dinoConfettiYellow, .dinoConfettiBlue, .dinoConfettiGreen, .dinoConfettiOrange
    ]
    static let particleBirthRate: CGFloat = 220
    static let particleLifetime: CGFloat = 1.1
    static let particleSpeed: CGFloat = 220
    static let particleSpeedRange: CGFloat = 120
    static let emissionAngleRange: CGFloat = .pi * 2 // burst in all directions
    static let particleScale: CGFloat = 0.22
    static let particleSize: CGFloat = 14

    /// Cached so we only rasterize the particle texture once per app run.
    private static var cachedTexture: SKTexture?

    static func makeConfetti() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture()
        emitter.particleBirthRate = particleBirthRate
        emitter.numParticlesToEmit = 90
        emitter.particleLifetime = particleLifetime
        emitter.particleLifetimeRange = particleLifetime * 0.4
        emitter.particleSpeed = particleSpeed
        emitter.particleSpeedRange = particleSpeedRange
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = emissionAngleRange
        emitter.particleScale = particleScale
        emitter.particleScaleRange = particleScale * 0.5
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.0 / Double(particleLifetime)
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 3.0
        emitter.yAcceleration = -260 // gentle gravity so it falls back down
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = nil
        emitter.particleColor = colors.randomElement() ?? .white

        // Cycle through the palette by giving each particle a random color
        // via a keyframed color ramp (SpriteKit re-evaluates per particle).
        let sequence = SKKeyframeSequence(keyframeValues: colors, times: colors.indices.map {
            NSNumber(value: Double($0) / Double(max(colors.count - 1, 1)))
        })
        emitter.particleColorSequence = sequence

        return emitter
    }

    private static func texture() -> SKTexture {
        if let cachedTexture { return cachedTexture }
        let shape = SKShapeNode(rectOf: CGSize(width: particleSize, height: particleSize * 0.6), cornerRadius: 2)
        shape.fillColor = .white
        shape.strokeColor = .clear
        let view = SKView(frame: CGRect(x: 0, y: 0, width: particleSize * 2, height: particleSize * 2))
        let texture = view.texture(from: shape) ?? SKTexture()
        cachedTexture = texture
        return texture
    }
}

extension SKColor {
    static let dinoConfettiPink = SKColor(red: 0.95, green: 0.45, blue: 0.62, alpha: 1.0)
    static let dinoConfettiYellow = SKColor(red: 0.98, green: 0.80, blue: 0.25, alpha: 1.0)
    static let dinoConfettiBlue = SKColor(red: 0.35, green: 0.65, blue: 0.95, alpha: 1.0)
    static let dinoConfettiGreen = SKColor(red: 0.45, green: 0.80, blue: 0.45, alpha: 1.0)
    static let dinoConfettiOrange = SKColor(red: 0.97, green: 0.60, blue: 0.25, alpha: 1.0)
}
