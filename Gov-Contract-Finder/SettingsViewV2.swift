import SwiftUI

struct SettingsViewV2: View {
    private let supportIssuesURL = URL(string: "https://github.com/fredylopez/Gov-Contract-Finder/issues")
    private let supportEmail = "support@codebodydynamics.com"

    @Bindable var themeController: ThemeController
    @Bindable var watchlistStore: WatchlistStore
    @Bindable var alertsStore: AlertsStore
    @Bindable var workspaceStore: WorkspaceStore

    @State private var didReset = false

    var body: some View {
        SafeEdgeScrollColumn(maxContentWidth: 820) {
            header
            appearanceSection
            aboutSection
            notificationsSection
            supportSection
            dataSection
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

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
            Text("Settings")
                .font(DesignTokensV2.Typography.hero)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)
            BoundedBodyText(value: "Customize your app experience")
        }
    }

    private var appearanceSection: some View {
        NeoCard {
            HStack(spacing: DesignTokensV2.Spacing.xs) {
                Image(systemName: "gearshape")
                    .foregroundStyle(DesignTokensV2.Colors.accentCyan)
                Text("Appearance")
                    .font(DesignTokensV2.Typography.section)
                    .foregroundStyle(DesignTokensV2.Colors.textPrimary)
            }

            BoundedBodyText(value: "Choose how Gov Contract Finder looks on your device")

            HStack(spacing: DesignTokensV2.Spacing.xs) {
                ForEach(AppearanceModeV2.allCases) { mode in
                    Button {
                        themeController.setPreferenceV2(mode)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: icon(for: mode))
                            Text(mode.title)
                        }
                        .font(DesignTokensV2.Typography.bodyStrong)
                        .foregroundStyle(themeController.preferenceV2 == mode ? DesignTokensV2.Colors.bg900 : DesignTokensV2.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokensV2.Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                                .fill(themeController.preferenceV2 == mode ? DesignTokensV2.Colors.accentCyan : DesignTokensV2.Colors.surface2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var aboutSection: some View {
        NeoCard {
            Text("About")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            BoundedBodyText(value: "Version:")
            BoundedBodyText(value: "1.0.0", font: DesignTokensV2.Typography.bodyStrong, color: DesignTokensV2.Colors.textPrimary)

            BoundedBodyText(value: "Purpose:")
            BoundedBodyText(value: "Help small contractors and consulting teams find federal opportunities quickly and reach out to contracting contacts.", color: DesignTokensV2.Colors.textPrimary)

            BoundedBodyText(value: "Data Source:")
            BoundedBodyText(value: "SAM.gov API", font: DesignTokensV2.Typography.bodyStrong, color: DesignTokensV2.Colors.textPrimary)
        }
    }

    private var notificationsSection: some View {
        NeoCard {
            Text("Notifications")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    BoundedBodyText(value: "New Opportunities", font: DesignTokensV2.Typography.bodyStrong, color: DesignTokensV2.Colors.textPrimary)
                    BoundedBodyText(value: "Get notified when new contracts match your filters")
                }
                Spacer()
                Toggle("", isOn: ruleEnabledBinding(for: .newOpportunity))
                    .labelsHidden()
                    .tint(DesignTokensV2.Colors.accentCyan)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    BoundedBodyText(value: "Response Deadlines", font: DesignTokensV2.Typography.bodyStrong, color: DesignTokensV2.Colors.textPrimary)
                    BoundedBodyText(value: "Reminders for upcoming due dates")
                }
                Spacer()
                Toggle("", isOn: ruleEnabledBinding(for: .deadline))
                    .labelsHidden()
                    .tint(DesignTokensV2.Colors.accentCyan)
            }
        }
    }

    @ViewBuilder
    private var supportSection: some View {
        NeoCard {
            Text("Support")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            if let supportIssuesURL {
                Link(destination: supportIssuesURL) {
                    Label("Open GitHub Support Page", systemImage: "link")
                        .font(DesignTokensV2.Typography.bodyStrong)
                        .foregroundStyle(DesignTokensV2.Colors.accentCyan)
                }
            }

            if let emailURL = URL(string: "mailto:\(supportEmail)") {
                Link(destination: emailURL) {
                    Label("Email \(supportEmail)", systemImage: "envelope")
                        .font(DesignTokensV2.Typography.bodyStrong)
                        .foregroundStyle(DesignTokensV2.Colors.accentCyan)
                }
            }
        }
    }

    private var dataSection: some View {
        NeoCard {
            Text("Local Data")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            let hasKey = APIKeyProvider.samKey() != nil
            HStack(spacing: DesignTokensV2.Spacing.xs) {
                Circle()
                    .fill(hasKey ? DesignTokensV2.Colors.success : DesignTokensV2.Colors.danger)
                    .frame(width: 10, height: 10)
                BoundedBodyText(
                    value: hasKey ? "SAM API connected" : "SAM API key missing",
                    color: DesignTokensV2.Colors.textPrimary
                )
            }

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

            Toggle("V2 Shell Enabled", isOn: Binding(
                get: { FeatureFlags.shared.v2ShellEnabled },
                set: { FeatureFlags.shared.v2ShellEnabled = $0 }
            ))
            .tint(DesignTokensV2.Colors.accentCyan)
            .foregroundStyle(DesignTokensV2.Colors.textPrimary)
        }
        #endif
    }

    private func icon(for mode: AppearanceModeV2) -> String {
        switch mode {
        case .system:
            return "desktopcomputer"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }

    private func ruleEnabledBinding(for type: AlertType) -> Binding<Bool> {
        Binding(
            get: { alertsStore.rules.first(where: { $0.type == type })?.enabled ?? false },
            set: { newValue in
                if let existing = alertsStore.rules.first(where: { $0.type == type }) {
                    alertsStore.setRuleEnabled(id: existing.id, enabled: newValue)
                } else {
                    alertsStore.rules.append(
                        AlertRule(
                            id: "rule_\(type.rawValue)",
                            type: type,
                            enabled: newValue,
                            keyword: "",
                            createdAt: Date()
                        )
                    )
                }
            }
        )
    }
}
