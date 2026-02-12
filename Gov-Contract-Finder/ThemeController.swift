//
//  ThemeController.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import SwiftUI
import Observation

@Observable
class ThemeController {
    var colorScheme: SwiftUI.ColorScheme? = nil

    private let storageKey = "preferredColorScheme"

    init() {
        let stored = UserDefaults.standard.string(forKey: storageKey)
        switch stored {
        case "dark":
            colorScheme = .dark
        case "light":
            colorScheme = .light
        default:
            colorScheme = nil
        }
    }

    func toggle() {
        // Cycle through: dark -> light -> system(nil) -> dark
        switch colorScheme {
        case .some(.dark):
            colorScheme = .light
        case .some(.light):
            colorScheme = nil
        case .none:
            colorScheme = .dark
        @unknown default:
            // In case ColorScheme gains new cases in the future, fall back to system
            colorScheme = nil
        }

        let value: String
        switch colorScheme {
        case .some(.dark):
            value = "dark"
        case .some(.light):
            value = "light"
        case .none:
            value = "system"
        @unknown default:
            value = "system"
        }
        UserDefaults.standard.set(value, forKey: storageKey)
    }
}

