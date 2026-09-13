import Foundation
import Observation

enum ControlScheme: String, CaseIterable {
    case drag, buttons, tilt

    var label: String {
        switch self {
        case .drag:    return "Drag"
        case .buttons: return "Buttons"
        case .tilt:    return "Tilt"
        }
    }

    var hint: String {
        switch self {
        case .drag:
            return "Move your thumb anywhere on the screen. Whatever you are steering moves the same distance, so your thumb never covers it."
        case .buttons:
            return "Two pads sit at the bottom of the screen."
        case .tilt:
            return "Tip the phone left and right. Recentre below to make however you are holding it count as straight ahead."
        }
    }
}

enum TiltSensitivity: String, CaseIterable {
    case low, mid, high

    var label: String {
        switch self {
        case .low:  return "Gentle"
        case .mid:  return "Normal"
        case .high: return "Twitchy"
        }
    }

    /// Degrees of tilt needed for a full-stick reading.
    var gain: CGFloat {
        switch self {
        case .low:  return 34
        case .mid:  return 22
        case .high: return 15
        }
    }
}

/// One shared settings object. Every change writes straight through to Store,
/// exactly as `Settings.save()` did.
@Observable
final class Settings {
    static let shared = Settings()

    var controls: ControlScheme    { didSet { Store.write("controls", controls.rawValue) } }
    var tilt: TiltSensitivity      { didSet { Store.write("tilt", tilt.rawValue) } }
    var tiltZero: Double           { didSet { Store.write("tiltZero", tiltZero) } }
    var sound: Bool                { didSet { Store.write("sound", sound) } }
    var haptics: Bool              { didSet { Store.write("haptics", haptics) } }
    var lefty: Bool                { didSet { Store.write("lefty", lefty) } }

    private init() {
        controls = ControlScheme(rawValue: Store.read("controls", "drag")) ?? .drag
        tilt     = TiltSensitivity(rawValue: Store.read("tilt", "mid")) ?? .mid
        tiltZero = Store.read("tiltZero", 0.0)
        sound    = Store.read("sound", true)
        haptics  = Store.read("haptics", true)
        lefty    = Store.read("lefty", false)
    }
}
