import SwiftUI
import Observation

enum ThemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

@Observable
final class ThemeController {
    var preference: ThemePreference = .system

    private let storageKey = "preferredColorScheme"

    init() {
        let stored = UserDefaults.standard.string(forKey: storageKey)
        preference = ThemePreference(rawValue: stored ?? "") ?? .system
    }

    func setPreference(_ newValue: ThemePreference) {
        preference = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
    }

    var preferenceV2: AppearanceModeV2 {
        AppearanceModeV2(rawValue: preference.rawValue) ?? .system
    }

    func setPreferenceV2(_ newValue: AppearanceModeV2) {
        setPreference(ThemePreference(rawValue: newValue.rawValue) ?? .system)
    }
}
