//
//  SettingsView.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 2/13/26.
//

import Observation
import SwiftUI

struct SettingsView: View {
    @Bindable var themeController: ThemeController
    @Bindable var tipJarStore: TipJarStore

    var body: some View {
        ZStack {
            LuxuryBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                    Text("Settings")
                        .font(DesignSystem.Typography.titleXL)
                        .foregroundStyle(DesignSystem.Colors.primaryText)

                    appearanceCard
                    tipJarCard
                }
                .frame(maxWidth: 360, alignment: .leading)
                .safeAreaPadding(.horizontal, 24)
                .safeAreaPadding(.top, 16)
                .safeAreaPadding(.bottom, 24)
            }
        }
    }

    private var appearanceCard: some View {
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

    private var tipJarCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Label("Tip Jar", systemImage: "heart.circle.fill")
                .font(DesignSystem.Typography.titleM)
                .foregroundStyle(DesignSystem.Colors.primaryText)

            Text("One-time tips help fund app updates and infrastructure.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.secondaryText)

            if tipJarStore.isLoadingProducts && tipJarStore.productsByTier.isEmpty {
                ProgressView("Loading tip options...")
            }

            ForEach(TipJarStore.TipTier.allCases) { tier in
                tipButton(for: tier)
            }

            if let statusMessage = tipJarStore.statusMessage {
                Text(statusMessage)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        }
        .cardStyle()
        .task {
            await tipJarStore.startIfNeeded()
        }
    }

    private func tipButton(for tier: TipJarStore.TipTier) -> some View {
        Button {
            Task {
                await tipJarStore.purchase(tier)
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.s) {
                if tipJarStore.purchasingTierID == tier.id {
                    ProgressView()
                } else {
                    Image(systemName: tier.icon)
                }

                Text(
                    tipJarStore.purchasingTierID == tier.id
                        ? "Processing..."
                        : "\(tier.title) • \(tipJarStore.price(for: tier))"
                )
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(DesignSystem.Colors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.vertical, DesignSystem.Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DesignSystem.Colors.surface)
            )
        }
        .buttonStyle(.plain)
        .disabled(tipJarStore.purchasingTierID != nil)
    }
}

#Preview {
    SettingsView(themeController: ThemeController(), tipJarStore: TipJarStore())
}
