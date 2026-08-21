import Foundation

/// A small deterministic PRNG (SplitMix64) so procedurally generated levels
/// are *reproducible* - level 7 looks the same every time you visit it in a
/// session, instead of reshuffling on every replay, which would be
/// confusing mid-demo ("wait, where did the rock go?").
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state, which would make SplitMix64 degenerate.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
