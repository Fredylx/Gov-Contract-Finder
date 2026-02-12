//
//  ButtonStyles.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 2/12/26.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(DesignSystem.Colors.accentTeal)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radii.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(DesignSystem.Colors.accentNavy)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radii.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.92 : 1.0)
    }
}
