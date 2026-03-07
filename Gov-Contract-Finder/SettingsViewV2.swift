import SwiftUI

struct SettingsViewV2: View {
    @Bindable var themeController: ThemeController
    @Bindable var watchlistStore: WatchlistStore
    @Bindable var alertsStore: AlertsStore
    @Bindable var workspaceStore: WorkspaceStore

    @State private var didReset = false

    var body: some View {
        SafeEdgeScrollColumn {
            appearanceSection
            apiSection
            storageSection
            debugSection
        }
        .background(CyberpunkBackgroundV2())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Data Cleared", isPresented: $didReset) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Watchlist, alerts, and workspace data were reset.")
        }
    }

    private var appearanceSection: some View {
        NeoCard {
            Text("Appearance")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            BoundedBodyText(value: "Choose your preferred appearance mode.")

            Picker("Theme", selection: Binding(
                get: { themeController.preferenceV2 },
                set: { themeController.setPreferenceV2($0) }
            )) {
                ForEach(AppearanceModeV2.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(DesignTokensV2.Colors.accentCyan)
        }
    }

    private var apiSection: some View {
        NeoCard {
            Text("SAM API")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            let hasKey = APIKeyProvider.samKey() != nil
            HStack {
                Circle()
                    .fill(hasKey ? DesignTokensV2.Colors.success : DesignTokensV2.Colors.danger)
                    .frame(width: 10, height: 10)
                BoundedBodyText(
                    value: hasKey ? "API key detected" : "API key missing",
                    color: DesignTokensV2.Colors.textPrimary
                )
            }

            BoundedBodyText(value: "Discover and Opportunity Detail use real SAM.gov data.")
        }
    }

    private var storageSection: some View {
        NeoCard {
            Text("Local Data")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            BoundedBodyText(value: "Watchlist, alerts, and workspace are stored on-device.")

            Button("Reset Local Data") {
                watchlistStore.reset()
                alertsStore.reset()
                workspaceStore.reset()
                didReset = true
            }
            .font(DesignTokensV2.Typography.bodyStrong)
            .foregroundStyle(DesignTokensV2.Colors.danger)
        }
    }

    @ViewBuilder
    private var debugSection: some View {
        #if DEBUG
        NeoCard {
            Text("Debug")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            BoundedBodyText(value: "V2 shell feature flag can be toggled in local settings.")

            Toggle("V2 Shell Enabled", isOn: Binding(
                get: { FeatureFlags.shared.v2ShellEnabled },
                set: { FeatureFlags.shared.v2ShellEnabled = $0 }
            ))
            .tint(DesignTokensV2.Colors.accentCyan)
            .foregroundStyle(DesignTokensV2.Colors.textPrimary)
        }
        #endif
    }
}
