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

    func toggle() {
        colorScheme = colorScheme == .dark ? .light : .dark
    }
}
