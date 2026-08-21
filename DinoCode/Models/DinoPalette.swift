import SpriteKit

/// A skin: just three named colors. Everything else about how the dino
/// looks (outline shade, foot shade) is *derived* from these via
/// `darkened(by:)` (see `SKColorExtensions.swift`) so picking a new skin is
/// only ever "pick 3 colors that look nice together" - the shape geometry
/// in `DinoShapeBuilder` never changes between skins.
struct DinoPalette: Identifiable, Equatable {
    let id: String
    let displayName: String
    let bodyColor: SKColor
    let bellyColor: SKColor
    let snoutColor: SKColor

    /// Outline stroke for body/head/legs/tail - a noticeably darker shade of
    /// the body color so it reads as "this dino's outline", not black.
    var outlineColor: SKColor { bodyColor.darkened(by: 0.45) }

    /// Feet are a shade darker than the body so they ground the character.
    var footColor: SKColor { bodyColor.darkened(by: 0.22) }

    static func == (lhs: DinoPalette, rhs: DinoPalette) -> Bool { lhs.id == rhs.id }
}

enum DinoSkins {
    static let meadow = DinoPalette(
        id: "meadow",
        displayName: "Meadow",
        bodyColor: SKColor(red: 0.33, green: 0.72, blue: 0.40, alpha: 1.0),
        bellyColor: SKColor(red: 0.80, green: 0.94, blue: 0.68, alpha: 1.0),
        snoutColor: SKColor(red: 0.85, green: 0.96, blue: 0.76, alpha: 1.0)
    )

    static let sunset = DinoPalette(
        id: "sunset",
        displayName: "Sunset",
        bodyColor: SKColor(red: 0.93, green: 0.55, blue: 0.24, alpha: 1.0),
        bellyColor: SKColor(red: 0.99, green: 0.85, blue: 0.62, alpha: 1.0),
        snoutColor: SKColor(red: 1.00, green: 0.90, blue: 0.72, alpha: 1.0)
    )

    static let berry = DinoPalette(
        id: "berry",
        displayName: "Berry",
        bodyColor: SKColor(red: 0.64, green: 0.40, blue: 0.82, alpha: 1.0),
        bellyColor: SKColor(red: 0.92, green: 0.82, blue: 0.97, alpha: 1.0),
        snoutColor: SKColor(red: 0.95, green: 0.87, blue: 0.98, alpha: 1.0)
    )

    static let all: [DinoPalette] = [meadow, sunset, berry]
}
