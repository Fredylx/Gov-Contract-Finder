import Observation
import SwiftUI

struct SettingsView: View {
    private let supportIssuesURL = URL(string: "https://github.com/Fredylx/Gov-Contract-Finder/blob/codex/submission-v1.1/SUPPORT.md")
    private let privacyPolicyURL = URL(string: "https://github.com/Fredylx/Gov-Contract-Finder/blob/codex/submission-v1.1/PRIVACY.md")
    private let supportEmail = "support@codebodydynamics.com"

    @Bindable var themeController: ThemeController
    @Bindable var watchlistStore: WatchlistStore
    @Bindable var alertsStore: AlertsStore
    @Bindable var workspaceStore: WorkspaceStore
    @Bindable var tipJarStore: TipJarStore
    @State private var didReset = false
    @State private var isShowingSupportAd = false
    @State private var isShowingDonateAd = false
    @State private var debugSettings = DebugSettings.shared

    var body: some View {
        SafeEdgeScrollColumn(maxContentWidth: 820) {
            header
            appearanceSection
            aboutSection
            notificationsSection
            adPrivacySection
            supportSection
            tipJarSection
            if shouldShowInternalSettings {
                dataSection
                debugSection
            }
        }
        .background(CyberpunkBackground())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Data Cleared", isPresented: $didReset) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Watchlist, alerts, and workspace data were reset.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Settings")
                .font(DesignTokens.Typography.hero)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            BoundedBodyText(value: "Customize your app experience")
        }
    }

    private var appearanceSection: some View {
        NeoCard {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "gearshape")
                    .foregroundStyle(DesignTokens.Colors.accentCyan)
                Text("Appearance")
                    .font(DesignTokens.Typography.section)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            BoundedBodyText(value: "Choose how Gov Contract Hunter looks on your device")

            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        themeController.setPreference(mode)
                        SearchAdsCoordinator.shared.triggerAfterUserAction("settings_theme_\(mode.rawValue)")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: icon(for: mode))
                            Text(mode.title)
                        }
                        .font(DesignTokens.Typography.bodyStrong)
                        .foregroundStyle(themeController.preference == mode ? DesignTokens.Colors.bg900 : DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                                .fill(themeController.preference == mode ? DesignTokens.Colors.accentCyan : DesignTokens.Colors.surface2)
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
                .font(DesignTokens.Typography.section)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            BoundedBodyText(value: "Version:")
            BoundedBodyText(value: "1.0.0", font: DesignTokens.Typography.bodyStrong, color: DesignTokens.Colors.textPrimary)

            BoundedBodyText(value: "Purpose:")
            BoundedBodyText(value: "Help small contractors and consulting teams find federal opportunities quickly and reach out to contracting contacts.", color: DesignTokens.Colors.textPrimary)
        }
    }

    private var notificationsSection: some View {
        NeoCard {
            Text("Notifications")
                .font(DesignTokens.Typography.section)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    BoundedBodyText(value: "New Opportunities", font: DesignTokens.Typography.bodyStrong, color: DesignTokens.Colors.textPrimary)
                    BoundedBodyText(value: "Get notified when new contracts match your filters")
                }
                Spacer()
                Toggle("", isOn: ruleEnabledBinding(for: .newOpportunity))
                    .labelsHidden()
                    .tint(DesignTokens.Colors.accentCyan)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    BoundedBodyText(value: "Response Deadlines", font: DesignTokens.Typography.bodyStrong, color: DesignTokens.Colors.textPrimary)
                    BoundedBodyText(value: "Reminders for upcoming due dates")
                }
                Spacer()
                Toggle("", isOn: ruleEnabledBinding(for: .deadline))
                    .labelsHidden()
                    .tint(DesignTokens.Colors.accentCyan)
            }
        }
    }

    private var adPrivacySection: some View {
        NeoCard {
            Text("Ad Privacy")
                .font(DesignTokens.Typography.section)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            BoundedBodyText(value: "This app uses non-personalized ads only.")
            BoundedBodyText(value: "Ads help support Gov Contract Hunter without tracking you across apps or websites.")
            BoundedBodyText(value: "Google AdMob may process limited device and usage data needed to load non-personalized ads, prevent fraud, and measure delivery.")

            HStack(spacing: DesignTokens.Spacing.xs) {
                if let privacyPolicyURL {
                    Link(destination: privacyPolicyURL) {
                        Label("Open Privacy Policy", systemImage: "lock.shield")
                            .font(DesignTokens.Typography.bodyStrong)
                            .foregroundStyle(DesignTokens.Colors.accentCyan)
                    }
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var supportSection: some View {
        NeoCard {
            Text("Support")
                .font(DesignTokens.Typography.section)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if let supportIssuesURL {
                Link(destination: supportIssuesURL) {
                    Label("Open Support Page", systemImage: "link")
                        .font(DesignTokens.Typography.bodyStrong)
                        .foregroundStyle(DesignTokens.Colors.accentCyan)
                }
            }

            if let privacyPolicyURL {
                Link(destination: privacyPolicyURL) {
                    Label("Open Privacy Policy", systemImage: "lock.shield")
                        .font(DesignTokens.Typography.bodyStrong)
                        .foregroundStyle(DesignTokens.Colors.accentCyan)
                }
            }

            if let emailURL = URL(string: "mailto:\(supportEmail)") {
                Link(destination: emailURL) {
                    Label("Email \(supportEmail)", systemImage: "envelope")
                        .font(DesignTokens.Typography.bodyStrong)
                        .foregroundStyle(DesignTokens.Colors.accentCyan)
                }
            }

            Button {
                Task {
                    isShowingSupportAd = true
                    _ = await SearchAdsCoordinator.shared.showSupportAdAsGift()
                    isShowingSupportAd = false
                }
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    if isShowingSupportAd {
                        ProgressView()
                            .tint(DesignTokens.Colors.bg900)
                    } else {
                        Image(systemName: "gift")
                    }
                    Text(isShowingSupportAd ? "Loading support ad..." : "Support the Developer")
                }
                .font(DesignTokens.Typography.bodyStrong)
                .foregroundStyle(DesignTokens.Colors.bg900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.accentLime, DesignTokens.Colors.accentCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isShowingSupportAd)

            Button {
                Task {
                    isShowingDonateAd = true
                    _ = await SearchAdsCoordinator.shared.showSupportAdAsGift()
                    isShowingDonateAd = false
                }
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    if isShowingDonateAd {
                        ProgressView()
                            .tint(DesignTokens.Colors.bg900)
                    } else {
                        Image(systemName: "heart.fill")
                    }
                    Text(isShowingDonateAd ? "Loading donation ad..." : "Donate with Ad")
                }
                .font(DesignTokens.Typography.bodyStrong)
                .foregroundStyle(DesignTokens.Colors.bg900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.accentMagenta, DesignTokens.Colors.accentViolet],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isShowingDonateAd)
        }
    }

    private var tipJarSection: some View {
        NeoCard {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.accentMagenta)
                Text("Tip Jar")
                    .font(DesignTokens.Typography.section)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            BoundedBodyText(value: "One-time tips help fund app updates and infrastructure.")

            if tipJarStore.isLoadingProducts && tipJarStore.productsByTier.isEmpty {
                ProgressView("Loading tip options...")
                    .tint(DesignTokens.Colors.accentCyan)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            ForEach(TipJarStore.TipTier.allCases) { tier in
                Button {
                    Task {
                        await tipJarStore.purchase(tier)
                    }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        if tipJarStore.purchasingTierID == tier.id {
                            ProgressView()
                                .tint(DesignTokens.Colors.bg900)
                        } else {
                            Image(systemName: tier.icon)
                        }

                        Text(tipJarStore.purchasingTierID == tier.id ? "Processing..." : "\(tier.title) • \(tipJarStore.price(for: tier))")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .font(DesignTokens.Typography.bodyStrong)
                    .foregroundStyle(DesignTokens.Colors.bg900)
                    .padding(.horizontal, DesignTokens.Spacing.m)
                    .padding(.vertical, DesignTokens.Spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [DesignTokens.Colors.accentCyan, DesignTokens.Colors.accentViolet],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(tipJarStore.purchasingTierID != nil)
            }

            if let statusMessage = tipJarStore.statusMessage {
                BoundedBodyText(value: statusMessage, font: DesignTokens.Typography.caption, color: DesignTokens.Colors.textSecondary)
            }
        }
        .task {
            await tipJarStore.startIfNeeded()
        }
    }

    private var dataSection: some View {
        NeoCard {
            Text("Local Data")
                .font(DesignTokens.Typography.section)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            let hasKey = APIKeyProvider.samKey() != nil
            HStack(spacing: DesignTokens.Spacing.xs) {
                Circle()
                    .fill(hasKey ? DesignTokens.Colors.success : DesignTokens.Colors.danger)
                    .frame(width: 10, height: 10)
                BoundedBodyText(
                    value: hasKey ? "SAM API connected" : "SAM API key missing",
                    color: DesignTokens.Colors.textPrimary
                )
            }

            Button("Reset Local Data") {
                watchlistStore.reset()
                alertsStore.reset()
                workspaceStore.reset()
                didReset = true
                SearchAdsCoordinator.shared.triggerAfterUserAction("settings_reset_local_data")
            }
            .font(DesignTokens.Typography.bodyStrong)
            .foregroundStyle(DesignTokens.Colors.danger)
        }
    }

    @ViewBuilder
    private var debugSection: some View {
        #if DEBUG
        NeoCard {
            Text("Debug")
                .font(DesignTokens.Typography.section)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Toggle("Search Ads Enabled", isOn: Binding(
                get: { FeatureFlags.shared.searchAdsEnabled },
                set: { FeatureFlags.shared.searchAdsEnabled = $0 }
            ))
            .tint(DesignTokens.Colors.accentCyan)
            .foregroundStyle(DesignTokens.Colors.textPrimary)

            Toggle("CCM Walkthrough Enabled", isOn: Binding(
                get: { FeatureFlags.shared.ccmWalkthroughEnabled },
                set: { FeatureFlags.shared.ccmWalkthroughEnabled = $0 }
            ))
            .tint(DesignTokens.Colors.accentCyan)
            .foregroundStyle(DesignTokens.Colors.textPrimary)

            Toggle("Live Alerts Refresh", isOn: Binding(
                get: { FeatureFlags.shared.liveAlertsRefreshEnabled },
                set: { FeatureFlags.shared.liveAlertsRefreshEnabled = $0 }
            ))
            .tint(DesignTokens.Colors.accentCyan)
            .foregroundStyle(DesignTokens.Colors.textPrimary)

            Toggle("Show Search Coach", isOn: $debugSettings.shouldShowSearchCoach)
                .tint(DesignTokens.Colors.accentCyan)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            BoundedBodyText(value: "Data Source:", font: DesignTokens.Typography.caption)
            BoundedBodyText(value: "SAM.gov API", font: DesignTokens.Typography.bodyStrong, color: DesignTokens.Colors.textPrimary)

            BoundedBodyText(
                value: "CCM Walkthrough Enabled gates the automatic first-run walkthrough. Show Search Coach still jumps to Discover and replays the coaching overlay, then switches itself off after the walkthrough finishes.",
                font: DesignTokens.Typography.caption
            )
        }
        #endif
    }

    private var shouldShowInternalSettings: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private func icon(for mode: AppearanceMode) -> String {
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
                SearchAdsCoordinator.shared.triggerAfterUserAction("settings_alert_rule_\(type.rawValue)")
            }
        )
    }
}
