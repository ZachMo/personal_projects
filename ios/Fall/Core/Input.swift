import CoreMotion
import SpriteKit
import UIKit

/// One steering axis, however the player supplies it.
///
/// Games ask for `dragDelta()` (points moved since the last frame) and `axis`
/// (-1...1). Drag mode fills the first, buttons and tilt the second. This is the
/// same contract the web version had, so the game code ports across unchanged.
final class Input {
    static let shared = Input()

    var axis: CGFloat = 0
    var padAxis: CGFloat = 0
    var tiltDegrees: CGFloat = 0
    var tiltSeen = false

    var pointer: CGPoint = .zero
    var down = false

    /// Set by the running game.
    var onTap: ((CGPoint) -> Void)?
    var onPress: ((CGPoint) -> Void)?

    private var accum: CGFloat = 0
    private var lastX: CGFloat = 0
    private var pressedAt: TimeInterval = 0
    private var pressStart: CGPoint = .zero

    private let motion = CMMotionManager()

    private init() {}

    private var gain: CGFloat { Settings.shared.tilt.gain }

    func reset() {
        axis = 0; padAxis = 0; accum = 0
        down = false
        onTap = nil; onPress = nil
    }

    /// Points travelled since the last call, then zeroed.
    func dragDelta() -> CGFloat {
        defer { accum = 0 }
        return accum
    }

    // MARK: - Touch, fed by the gesture recogniser on the scene

    func pressed(at p: CGPoint) {
        down = true
        lastX = p.x
        accum = 0
        pointer = p
        pressedAt = CACurrentMediaTime()
        pressStart = p
        onPress?(p)
    }

    func moved(to p: CGPoint) {
        guard down else { return }
        accum += p.x - lastX
        lastX = p.x
        pointer = p
    }

    func released(at p: CGPoint) {
        guard down else { return }
        down = false
        accum = 0
        let moved = hypot(p.x - pressStart.x, p.y - pressStart.y)
        let quick = CACurrentMediaTime() - pressedAt < 0.4
        if moved < 18, quick { onTap?(p) }
    }

    // MARK: - Tilt

    func startMotion() {
        guard Settings.shared.controls == .tilt,
              motion.isDeviceMotionAvailable,
              !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let g = data?.gravity else { return }
            self.tiltSeen = true
            self.tiltDegrees = Self.lateralDegrees(gravity: g)
        }
    }

    func stopMotion() {
        motion.stopDeviceMotionUpdates()
    }

    /// The web version read `deviceorientation.gamma`, swapping to `beta` when the
    /// screen turned. CoreMotion reports gravity in device space, so the screen's
    /// left-right axis is picked out of it the same way.
    private static func lateralDegrees(gravity g: CMAcceleration) -> CGFloat {
        let lateral: Double
        let upright: Double
        switch UIApplication.shared.interfaceOrientation {
        case .landscapeLeft:
            lateral = -g.y; upright = hypot(g.x, g.z)
        case .landscapeRight:
            lateral = g.y;  upright = hypot(g.x, g.z)
        case .portraitUpsideDown:
            lateral = -g.x; upright = hypot(g.y, g.z)
        default:
            lateral = g.x;  upright = hypot(g.y, g.z)
        }
        return CGFloat(atan2(lateral, upright) * 180 / .pi)
    }

    /// However the phone is being held right now counts as straight ahead.
    func recentre() {
        Settings.shared.tiltZero = Double(tiltDegrees)
    }

    // MARK: - Per frame

    func step() {
        if Settings.shared.controls == .tilt {
            axis = clamp((tiltDegrees - CGFloat(Settings.shared.tiltZero)) / gain, -1, 1)
            if abs(axis) < 0.06 { axis = 0 }        // deadzone
        } else {
            axis = padAxis
        }
    }

    /// The one call games make to steer something horizontally.
    func steer(_ x: CGFloat, dt: CGFloat, speed: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        var x = x
        if Settings.shared.controls == .drag {
            x += dragDelta() * 1.15
        } else {
            x += axis * speed * dt
        }
        return clamp(x, lo, hi)
    }
}

extension UIApplication {
    var interfaceOrientation: UIInterfaceOrientation {
        (connectedScenes.first as? UIWindowScene)?.interfaceOrientation ?? .portrait
    }
}
