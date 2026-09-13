import AVFoundation
import Foundation

/// The web version synthesised every sound from oscillators so it could ship as
/// one file with nothing to load. This keeps that: buffers are rendered the
/// moment they are asked for, and there are still no audio files in the bundle.
///
/// The envelopes follow the WebAudio calls they replace — a 12 ms linear attack
/// into an exponential tail for `blip`, a straight exponential for `slide`.
final class Sound {
    static let shared = Sound()

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var next = 0
    private var ready = false
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private static let voices = 8
    private static let floorGain: Float = 0.0001   // WebAudio cannot ramp to zero

    private init() {}

    /// Called on the first real gesture, mirroring the `Sound.wake()` the web
    /// version needed to get past the autoplay rules.
    func wake() {
        guard !ready else {
            if !engine.isRunning { try? engine.start() }
            return
        }
        let session = AVAudioSession.sharedInstance()
        // Ambient keeps the player's own music going and respects the ring switch.
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        for _ in 0..<Self.voices {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }
        do {
            try engine.start()
            players.forEach { $0.play() }
            ready = true
        } catch {
            ready = false
        }
    }

    // MARK: - The three voices

    func blip(_ freq: Float, _ len: Double, _ shape: Wave = .sine, _ gain: Float = 0.16) {
        render(len) { s, t in
            Self.wave(shape, phase: t * Double(freq)) * Self.attackDecay(s, len, gain)
        }
    }

    func slide(from: Float, to: Float, _ len: Double, _ shape: Wave = .triangle) {
        let target = max(30, to)
        let ratio = Double(target / from)
        var phase = 0.0
        render(len) { s, _ in
            // Matches exponentialRampToValueAtTime on the frequency, integrated
            // so the phase stays continuous across the sweep.
            let f = Double(from) * pow(ratio, s / len)
            phase += f / 44_100
            return Self.wave(shape, phase: phase) * Self.decay(s, len, 0.14)
        }
    }

    func noise(_ len: Double, _ gain: Float = 0.2) {
        render(len) { s, _ in
            Float.random(in: -1...1) * gain * Float(1 - s / len)
        }
    }

    // MARK: - Envelopes

    /// 0 → gain over 12 ms, then an exponential tail to silence.
    private static func attackDecay(_ s: Double, _ len: Double, _ gain: Float) -> Float {
        let attack = 0.012
        if s < attack { return gain * Float(s / attack) }
        let span = max(0.001, len - attack)
        return gain * powf(floorGain / gain, Float((s - attack) / span))
    }

    /// Straight exponential from gain to silence.
    private static func decay(_ s: Double, _ len: Double, _ gain: Float) -> Float {
        gain * powf(floorGain / gain, Float(s / len))
    }

    // MARK: - Waveforms

    enum Wave { case sine, square, triangle, sawtooth }

    /// `phase` counts whole cycles, so the fractional part is the position in one.
    private static func wave(_ shape: Wave, phase: Double) -> Float {
        let p = phase - floor(phase)
        switch shape {
        case .sine:     return Float(sin(p * 2 * .pi))
        case .square:   return p < 0.5 ? 1 : -1
        case .sawtooth: return Float(p * 2 - 1)
        case .triangle: return Float(p < 0.5 ? (p * 4 - 1) : (3 - p * 4))
        }
    }

    // MARK: - Playback

    /// `body` is handed the seconds elapsed and the same figure again as the
    /// oscillator's time base, and returns one sample.
    private func render(_ len: Double, _ body: (Double, Double) -> Float) {
        guard Settings.shared.sound, ready, engine.isRunning else { return }
        let rate = format.sampleRate
        let frames = AVAudioFrameCount(max(1, len * rate))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frames

        for i in 0..<Int(frames) {
            let s = Double(i) / rate
            channel[i] = body(s, s)
        }

        let node = players[next]
        next = (next + 1) % players.count
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
    }
}
