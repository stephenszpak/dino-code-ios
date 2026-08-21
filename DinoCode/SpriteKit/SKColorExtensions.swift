import SpriteKit

extension SKColor {
    /// Returns a darker version of this color by scaling RGB down toward
    /// black. Used for simple shading (e.g. an outline color derived from a
    /// fill color) without needing a second named color constant everywhere.
    func darkened(by fraction: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let scale = 1 - fraction
        return SKColor(red: r * scale, green: g * scale, blue: b * scale, alpha: a)
    }
}
