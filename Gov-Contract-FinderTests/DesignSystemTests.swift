//
//  DesignSystemTests.swift
//  Gov-Contract-FinderTests
//
//  Created by Fredy lopez on 2/12/26.
//

import SwiftUI
import Testing
import UIKit
@testable import Gov_Contract_Finder

struct DesignSystemTests {
    @Test func hexColorParsingSixDigit() {
        let color = Color(hex: "#1F9D8E")
        let uiColor = UIColor(color)
        let components = rgba(from: uiColor)
        #expect(approx(components.r, 31), "R component")
        #expect(approx(components.g, 157), "G component")
        #expect(approx(components.b, 142), "B component")
        #expect(approx(components.a, 255), "A component")
    }

    @Test func hexColorParsingEightDigit() {
        let color = Color(hex: "#80112233")
        let uiColor = UIColor(color)
        let components = rgba(from: uiColor)
        #expect(approx(components.a, 128), "A component")
        #expect(approx(components.r, 17), "R component")
        #expect(approx(components.g, 34), "G component")
        #expect(approx(components.b, 51), "B component")
    }

    private func rgba(from color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r * 255, g * 255, b * 255, a * 255)
    }

    private func approx(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat = 1) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}
