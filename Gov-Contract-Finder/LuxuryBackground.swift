//
//  LuxuryBackground.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 2/12/26.
//

import SwiftUI

struct LuxuryBackground: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
            LinearGradient(
                colors: [
                    DesignSystem.Colors.background,
                    DesignSystem.Colors.backgroundAlt
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Image("noiseTexture")
                .resizable()
                .scaledToFill()
                .opacity(0.02)
                .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }
}
