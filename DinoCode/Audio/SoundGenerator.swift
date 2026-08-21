import AVFoundation

/// Generates short beep tones on the fly with `AVAudioEngine` instead of
/// bundling sound files - there's nothing to import, and every tunable
/// (pitch, length) is a plain constant below, which makes a nice "this is
/// all just code" moment to point at during the demo.
final class SoundGenerator {
    static let shared = SoundGenerator()

    // MARK: - Tunables

    private static let sampleRate: Double = 44_100
    private static let tapFrequency: Double = 660      // A5-ish blip on each arrow tap
    private static let tapDuration: Double = 0.08

    private static let stepFrequency: Double = 440     // low tick on each grid step
    private static let stepDuration: Double = 0.10

    private static let bonkFrequency: Double = 160      // low buzz on wall bump
    private static let bonkDuration: Double = 0.22

    /// Ascending 3-note arpeggio played on reaching the cookie.
    private static let winFrequencies: [Double] = [523.25, 659.25, 783.99] // C5, E5, G5
    private static let winNoteDuration: Double = 0.14

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    private init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 1)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()
        try? engine.start()
    }

    func playTapSound() {
        play(frequency: Self.tapFrequency, duration: Self.tapDuration)
    }

    func playStepSound() {
        play(frequency: Self.stepFrequency, duration: Self.stepDuration)
    }

    func playBonkSound() {
        play(frequency: Self.bonkFrequency, duration: Self.bonkDuration, waveform: .square)
    }

    func playWinSound() {
        var delay: Double = 0
        for frequency in Self.winFrequencies {
            let when = delay
            DispatchQueue.main.asyncAfter(deadline: .now() + when) { [weak self] in
                self?.play(frequency: frequency, duration: Self.winNoteDuration)
            }
            delay += Self.winNoteDuration
        }
    }

    // MARK: - Tone synthesis

    private enum Waveform { case sine, square }

    private func play(frequency: Double, duration: Double, waveform: Waveform = .sine) {
        guard let buffer = makeBuffer(frequency: frequency, duration: duration, waveform: waveform) else { return }
        if engine.isRunning == false {
            try? engine.start()
        }
        player.scheduleBuffer(buffer, at: nil, options: [.interrupts])
        player.play()
    }

    private func makeBuffer(frequency: Double, duration: Double, waveform: Waveform) -> AVAudioPCMBuffer? {
        let sampleRate = Self.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let channel = buffer.floatChannelData![0]
        let twoPiF = 2.0 * Double.pi * frequency
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            // Short fade-out envelope so notes don't click at the end.
            let envelope = 1.0 - (t / duration)
            let sample: Double
            switch waveform {
            case .sine:
                sample = sin(twoPiF * t)
            case .square:
                sample = sin(twoPiF * t) >= 0 ? 1.0 : -1.0
            }
            channel[frame] = Float(sample * envelope * 0.2)
        }
        return buffer
    }
}
