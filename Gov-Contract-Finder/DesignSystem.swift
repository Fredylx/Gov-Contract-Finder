//
//  DesignSystem.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 2/12/26.
//

import SwiftUI
import UIKit

enum DesignSystem {
    enum Colors {
        static let background = dynamicColor(light: "#F5F7FA", dark: "#0B1220")
        static let backgroundAlt = dynamicColor(light: "#EEF2F6", dark: "#111827")
        static let surface = dynamicColor(light: "#FFFFFF", dark: "#141C2B")
        static let primaryText = dynamicColor(light: "#111827", dark: "#F8FAFC")
        static let secondaryText = dynamicColor(light: "#4B5563", dark: "#C7CEDB")
        static let divider = dynamicColor(light: "#E5E7EB", dark: "#263143")
        static let accentTeal = dynamicColor(light: "#1F9D8E", dark: "#2CBFAE")
        static let accentNavy = dynamicColor(light: "#233B59", dark: "#4B6A96")
    }

    enum Typography {
        static let titleXL = Font.system(size: 28, weight: .bold)
        static let titleL = Font.system(size: 22, weight: .semibold)
        static let titleM = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 13, weight: .medium)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radii {
        static let card: CGFloat = 14
        static let button: CGFloat = 12
        static let modal: CGFloat = 20
    }

    enum Shadows {
        static let soft = ShadowStyle(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        static let elevated = ShadowStyle(color: .black.opacity(0.06), radius: 30, x: 0, y: 12)
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func dsShadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 8:
            a = (int >> 24) & 0xFF
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            a = 0xFF
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

private extension DesignSystem.Colors {
    static func dynamicColor(light: String, dark: String) -> Color {
        let lightColor = uiColor(hex: light)
        let darkColor = uiColor(hex: dark)
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? darkColor : lightColor
        })
    }

    static func uiColor(hex: String) -> UIColor {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 8:
            a = (int >> 24) & 0xFF
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            a = 0xFF
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        }
        return UIColor(red: CGFloat(r) / 255,
                       green: CGFloat(g) / 255,
                       blue: CGFloat(b) / 255,
                       alpha: CGFloat(a) / 255)
    }
}
