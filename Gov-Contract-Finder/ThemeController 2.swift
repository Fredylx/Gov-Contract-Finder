//
//  ThemeController.swift
//  Gov-Contract-Finder
//
//  Created by Assistant on 2/10/26.
//

import SwiftUI
import Combine

@MainActor
final class ThemeController: ObservableObject {
    @Published var colorScheme: ColorScheme?

    init(initialScheme: ColorScheme? = nil) {
        self.colorScheme = initialScheme
    }

    func toggle() {
        switch colorScheme {
        case nil:
            colorScheme = .light
        case .some(.light):
            colorScheme = .dark
        case .some(.dark):
            fallthrough
        @unknown default:
            colorScheme = nil
        }
    }

    func setLight() { colorScheme = .light }
    func setDark() { colorScheme = .dark }
    func setSystem() { colorScheme = nil }
}
