//
//  CardStyle.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 2/12/26.
//

import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.l)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radii.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radii.card, style: .continuous)
                    .stroke(DesignSystem.Colors.divider.opacity(0.6), lineWidth: 1)
            )
            .dsShadow(DesignSystem.Shadows.soft)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
