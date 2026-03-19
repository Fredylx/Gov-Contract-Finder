import SwiftUI
import Observation

@Observable
final class ThemeController {
    var preference: AppearanceMode = .system

    private let storageKey = "preferredColorScheme"

    init() {
        let stored = UserDefaults.standard.string(forKey: storageKey)
        preference = AppearanceMode(rawValue: stored ?? "") ?? .system
    }

    func setPreference(_ newValue: AppearanceMode) {
        preference = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
    }
}
