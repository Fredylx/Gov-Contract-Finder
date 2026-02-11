//
//  ThemeController.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import SwiftUI

@Observable
final class ThemeController {
    var colorScheme: ColorScheme? = nil

    private let storageKey = "preferredColorScheme"

    init() {
        if let stored = UserDefaults.standard.string(forKey: storageKey) {
            colorScheme = stored == "dark" ? .dark : stored == "light" ? .light : nil
        }
    }

    func toggle() {
        switch colorScheme {
        case .dark:
            colorScheme = .light
        case .light:
            colorScheme = nil
        default:
            colorScheme = .dark
        }
        let value: String
        if colorScheme == .dark {
            value = "dark"
        } else if colorScheme == .light {
            value = "light"
        } else {
            value = "system"
        }
        UserDefaults.standard.set(value, forKey: storageKey)
    }
}
