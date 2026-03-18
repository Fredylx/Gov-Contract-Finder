import Observation
import Foundation

@Observable
final class DebugSettings {
    static let shared = DebugSettings()

    private let isEnabledKey = "debugLoggingEnabled"
    private let showSearchCoachKey = "debugShowSearchCoach"
    let featureFlags = FeatureFlags.shared

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: isEnabledKey)
        }
    }

    var shouldShowSearchCoach: Bool {
        didSet {
            UserDefaults.standard.set(shouldShowSearchCoach, forKey: showSearchCoachKey)
        }
    }

    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: isEnabledKey) as? Bool ?? true
        self.shouldShowSearchCoach = UserDefaults.standard.bool(forKey: showSearchCoachKey)
    }
}
