import Observation
import Foundation

@Observable
final class DebugSettings {
    static let shared = DebugSettings()

    private let isEnabledKey = "debugLoggingEnabled"

    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: isEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: isEnabledKey) }
    }
}
