import SwiftUI

enum AppTabV2: Int, CaseIterable, Identifiable {
    case discover
    case watchlist
    case alerts
    case workspace
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .discover: return "Discover"
        case .watchlist: return "Watchlist"
        case .alerts: return "Alerts"
        case .workspace: return "Workspace"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .discover: return "magnifyingglass"
        case .watchlist: return "bookmark"
        case .alerts: return "bell"
        case .workspace: return "briefcase"
        case .settings: return "gearshape"
        }
    }
}

enum AppRouteV2: Hashable {
    case opportunity(id: String)
}

struct RootViewV2: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: AppTabV2 = .discover
    @State private var discoverPath: [AppRouteV2] = []
    @State private var watchlistPath: [AppRouteV2] = []
    @State private var alertsPath: [AppRouteV2] = []
    @State private var workspacePath: [AppRouteV2] = []
    @State private var settingsPath: [AppRouteV2] = []

    @State private var watchlistStore = WatchlistStore()
    @State private var alertsStore = AlertsStore()
    @State private var workspaceStore = WorkspaceStore()
    @State private var themeController = ThemeController()
    @State private var tipJarStore = TipJarStore()
    @State private var adConsentManager = AdConsentManager.shared
    @State private var firstRunDemoController = FirstRunDemoController()
    @State private var alertRefreshCoordinator = AlertRefreshCoordinator()
    @State private var toastController = TransientToastControllerV2()
    @State private var debugSettings = DebugSettings.shared
    @State private var featureFlags = FeatureFlags.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            CyberpunkBackgroundV2()
            Image("noiseTexture")
                .resizable(resizingMode: .tile)
                .opacity(0.06)
                .ignoresSafeArea()

            ZStack {
                NavigationStack(path: $discoverPath) {
                    DiscoverViewV2(
                        watchlistStore: watchlistStore,
                        alertsStore: alertsStore,
                        workspaceStore: workspaceStore,
                        firstRunDemoController: firstRunDemoController
                    ) {
                        toastController.show(text: "Thanks. Ads support Gov Contract Hunter.")
                    }
                    .navigationDestination(for: AppRouteV2.self) { route in
                        routeDestination(route)
                    }
                }
                .tabVisibility(isActive: selectedTab == .discover)

                NavigationStack(path: $watchlistPath) {
                    WatchlistViewV2(
                        watchlistStore: watchlistStore,
                        alertsStore: alertsStore,
                        workspaceStore: workspaceStore
                    )
                    .navigationDestination(for: AppRouteV2.self) { route in
                        routeDestination(route)
                    }
                }
                .tabVisibility(isActive: selectedTab == .watchlist)

                NavigationStack(path: $alertsPath) {
                    AlertsViewV2(
                        alertsStore: alertsStore,
                        lastCheckedAt: alertRefreshCoordinator.lastSuccessfulRefreshAt
                    ) { opportunityID in
                        openAlertOpportunity(opportunityID)
                    }
                        .navigationDestination(for: AppRouteV2.self) { route in
                            routeDestination(route)
                        }
                }
                .tabVisibility(isActive: selectedTab == .alerts)

                NavigationStack(path: $workspacePath) {
                    WorkspaceViewV2(workspaceStore: workspaceStore)
                        .navigationDestination(for: AppRouteV2.self) { route in
                            routeDestination(route)
                        }
                }
                .tabVisibility(isActive: selectedTab == .workspace)

                NavigationStack(path: $settingsPath) {
                    SettingsViewV2(
                        themeController: themeController,
                        watchlistStore: watchlistStore,
                        alertsStore: alertsStore,
                        workspaceStore: workspaceStore,
                        tipJarStore: tipJarStore,
                        adConsentManager: adConsentManager
                    )
                        .navigationDestination(for: AppRouteV2.self) { route in
                            routeDestination(route)
                        }
                }
                .tabVisibility(isActive: selectedTab == .settings)
            }

            CustomTabBarV2(selectedTab: $selectedTab)
                .allowsHitTesting(!isWalkthroughBlockingUI)
        }
        .overlay {
            if shouldShowIntroOverlay {
                FirstRunDemoIntroOverlayV2 {
                    startSearchCoach()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = toastController.currentToast {
                TransientToastViewV2(message: toast.text)
                    .padding(.bottom, 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .dismissKeyboardOnTap()
        .preferredColorScheme(themeController.preferenceV2.colorScheme)
        .onAppear {
            if shouldResumeAutomaticSearchCoach {
                navigateToSearchCoach()
            }

            if debugSettings.shouldShowSearchCoach {
                startSearchCoach()
            }
        }
        .onChange(of: firstRunDemoController.step) { _, step in
            if step.isLiveStep {
                selectedTab = .discover
                discoverPath.removeAll()
                settingsPath.removeAll()
            }

            if step.isFinished && debugSettings.shouldShowSearchCoach {
                debugSettings.shouldShowSearchCoach = false
            }
        }
        .onChange(of: debugSettings.shouldShowSearchCoach) { _, shouldShowSearchCoach in
            if shouldShowSearchCoach {
                startSearchCoach()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshAlertsIfNeeded()
        }
        .onChange(of: featureFlags.liveAlertsRefreshEnabled) { _, isEnabled in
            guard isEnabled else { return }
            refreshAlerts(force: true)
        }
        .task {
            await adConsentManager.prepareOnLaunch()
            if scenePhase == .active {
                await alertRefreshCoordinator.handleAppDidBecomeActive(
                    alertsStore: alertsStore,
                    watchlistStore: watchlistStore,
                    workspaceStore: workspaceStore
                )
            }
        }
    }

    @ViewBuilder
    private func routeDestination(_ route: AppRouteV2) -> some View {
        switch route {
        case .opportunity(let id):
            OpportunityDeepLinkViewV2(
                id: id,
                watchlistStore: watchlistStore,
                alertsStore: alertsStore,
                workspaceStore: workspaceStore
            )
        }
    }

    private func startSearchCoach() {
        navigateToSearchCoach()
        firstRunDemoController.startDemo()
    }

    private var shouldShowIntroOverlay: Bool {
        featureFlags.ccmWalkthroughEnabled && firstRunDemoController.isShowingIntro
    }

    private var shouldResumeAutomaticSearchCoach: Bool {
        featureFlags.ccmWalkthroughEnabled && firstRunDemoController.isShowingCoachMarks
    }

    private var isWalkthroughBlockingUI: Bool {
        shouldShowIntroOverlay || shouldShowAutomaticCoachMarks || debugSettings.shouldShowSearchCoach
    }

    private var shouldShowAutomaticCoachMarks: Bool {
        featureFlags.ccmWalkthroughEnabled && firstRunDemoController.isShowingCoachMarks
    }

    private func navigateToSearchCoach() {
        selectedTab = .discover
        discoverPath.removeAll()
        settingsPath.removeAll()
    }

    private func openAlertOpportunity(_ opportunityID: String) {
        selectedTab = .alerts
        alertsPath = [.opportunity(id: opportunityID)]
    }

    private func refreshAlertsIfNeeded() {
        refreshAlerts(force: false)
    }

    private func refreshAlerts(force: Bool) {
        Task {
            if force {
                await alertRefreshCoordinator.refreshNow(
                    alertsStore: alertsStore,
                    watchlistStore: watchlistStore,
                    workspaceStore: workspaceStore
                )
            } else {
                await alertRefreshCoordinator.handleAppDidBecomeActive(
                    alertsStore: alertsStore,
                    watchlistStore: watchlistStore,
                    workspaceStore: workspaceStore
                )
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func tabVisibility(isActive: Bool) -> some View {
        self
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
            .accessibilityHidden(!isActive)
            .zIndex(isActive ? 1 : 0)
    }
}

private struct OpportunityDeepLinkViewV2: View {
    let id: String
    let watchlistStore: WatchlistStore
    let alertsStore: AlertsStore
    let workspaceStore: WorkspaceStore

    var body: some View {
        Group {
            if let opportunity = resolvedOpportunity {
                OpportunityDetailView(
                    opportunity: opportunity,
                    watchlistStore: watchlistStore,
                    alertsStore: alertsStore,
                    workspaceStore: workspaceStore
                )
            } else {
                SafeEdgeScrollColumn {
                    NeoCard {
                        Text("Opportunity")
                            .font(DesignTokensV2.Typography.section)
                            .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                        BoundedBodyText(value: "Unable to resolve opportunity for id: \(id)")
                    }
                }
                .background(CyberpunkBackgroundV2())
            }
        }
    }

    private var resolvedOpportunity: Opportunity? {
        if let alertOpportunity = alertsStore.items.first(where: { $0.opportunityID == id })?.asOpportunity {
            return alertOpportunity
        }

        if let watchlistOpportunity = watchlistStore.items.first(where: { $0.opportunityID == id })?.asOpportunity {
            return watchlistOpportunity
        }

        if let workspaceOpportunity = workspaceStore.records.first(where: { $0.opportunityID == id })?.snapshot?.asOpportunity {
            return workspaceOpportunity
        }

        return nil
    }
}

struct CustomTabBarV2: View {
    @Binding var selectedTab: AppTabV2

    var body: some View {
        HStack(spacing: DesignTokensV2.Spacing.xs) {
            ForEach(AppTabV2.allCases) { tab in
                Button {
                    withAnimation(DesignTokensV2.Animation.smooth) {
                        selectedTab = tab
                    }
                    SearchAdsCoordinator.shared.triggerAfterUserAction("tab_\(tab.title.lowercased())")
                } label: {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(selectedTab == tab ? DesignTokensV2.Colors.accentCyan : DesignTokensV2.Colors.textSecondary)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                            .fill(selectedTab == tab ? DesignTokensV2.Colors.surface2 : .clear)
                    )
                }
                .accessibilityLabel(tab.title)
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokensV2.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.tabBar, style: .continuous)
                .fill(DesignTokensV2.Colors.bg800.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.tabBar, style: .continuous)
                .stroke(DesignTokensV2.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, DesignTokensV2.Spacing.l)
        .padding(.bottom, DesignTokensV2.Spacing.s)
    }
}
