//
//  SettingsView.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 2/13/26.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var themeController: ThemeController

    var body: some View {
        ZStack {
            LuxuryBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                    Text("Settings")
                        .font(DesignSystem.Typography.titleXL)
                        .foregroundStyle(DesignSystem.Colors.primaryText)

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("Appearance")
                            .font(DesignSystem.Typography.titleM)
                            .foregroundStyle(DesignSystem.Colors.primaryText)

                        Text("Choose how the app looks on your device.")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)

                        Picker("Theme", selection: Binding(
                            get: { themeController.preference },
                            set: { themeController.setPreference($0) }
                        )) {
                            ForEach(ThemePreference.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .cardStyle()
                }
                .frame(maxWidth: 360, alignment: .leading)
                .safeAreaPadding(.horizontal, 24)
                .safeAreaPadding(.top, 16)
                .safeAreaPadding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SettingsView(themeController: ThemeController())
}
