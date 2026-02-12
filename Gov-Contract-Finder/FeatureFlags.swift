import Foundation
import Observation

@Observable
final class FeatureFlags {
    static let shared = FeatureFlags()

    private let naicsPresetsKey = "feature.naicsPresets"
    private let sortControlKey = "feature.sortControl"
    private let darkModeToggleKey = "feature.darkModeToggle"

    var naicsPresetsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: naicsPresetsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: naicsPresetsKey) }
    }

    var sortControlEnabled: Bool {
        get { UserDefaults.standard.object(forKey: sortControlKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: sortControlKey) }
    }

    var darkModeToggleEnabled: Bool {
        get { UserDefaults.standard.object(forKey: darkModeToggleKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: darkModeToggleKey) }
    }
}
