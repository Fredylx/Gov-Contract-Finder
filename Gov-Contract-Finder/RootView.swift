import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
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

enum AppRoute: Hashable {
    case opportunity(id: String)
}

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: AppTab = .discover
    @State private var discoverPath: [AppRoute] = []
    @State private var watchlistPath: [AppRoute] = []
    @State private var alertsPath: [AppRoute] = []
    @State private var workspacePath: [AppRoute] = []
    @State private var settingsPath: [AppRoute] = []

    @State private var watchlistStore = WatchlistStore()
    @State private var alertsStore = AlertsStore()
    @State private var workspaceStore = WorkspaceStore()
    @State private var themeController = ThemeController()
    @State private var tipJarStore = TipJarStore()
    @State private var adConsentManager = AdConsentManager.shared
    @State private var firstRunDemoController = FirstRunDemoController()
    @State private var alertRefreshCoordinator = AlertRefreshCoordinator()
    @State private var toastController = TransientToastController()
    @State private var debugSettings = DebugSettings.shared
    @State private var featureFlags = FeatureFlags.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            CyberpunkBackground()
            Image("noiseTexture")
                .resizable(resizingMode: .tile)
                .opacity(0.06)
                .ignoresSafeArea()

            ZStack {
                NavigationStack(path: $discoverPath) {
                    DiscoverView(
                        watchlistStore: watchlistStore,
                        alertsStore: alertsStore,
                        workspaceStore: workspaceStore,
                        firstRunDemoController: firstRunDemoController
                    ) {
                        toastController.show(text: "Thanks. Ads support Gov Contract Hunter.")
                    }
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
                }
                .tabVisibility(isActive: selectedTab == .discover)

                NavigationStack(path: $watchlistPath) {
                    WatchlistView(
                        watchlistStore: watchlistStore,
                        alertsStore: alertsStore,
                        workspaceStore: workspaceStore
                    )
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
                }
                .tabVisibility(isActive: selectedTab == .watchlist)

                NavigationStack(path: $alertsPath) {
                    AlertsView(
                        alertsStore: alertsStore,
                        lastCheckedAt: alertRefreshCoordinator.lastSuccessfulRefreshAt
                    ) { opportunityID in
                        openAlertOpportunity(opportunityID)
                    }
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
                .tabVisibility(isActive: selectedTab == .alerts)

                NavigationStack(path: $workspacePath) {
                    WorkspaceView(workspaceStore: workspaceStore)
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
                .tabVisibility(isActive: selectedTab == .workspace)

                NavigationStack(path: $settingsPath) {
                    SettingsView(
                        themeController: themeController,
                        watchlistStore: watchlistStore,
                        alertsStore: alertsStore,
                        workspaceStore: workspaceStore,
                        tipJarStore: tipJarStore
                    )
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
                .tabVisibility(isActive: selectedTab == .settings)
            }

            CustomTabBar(selectedTab: $selectedTab)
                .allowsHitTesting(!isWalkthroughBlockingUI)
        }
        .overlay {
            if shouldShowIntroOverlay {
                FirstRunDemoIntroOverlay {
                    startSearchCoach()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = toastController.currentToast {
                TransientToastView(message: toast.text)
                    .padding(.bottom, 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .dismissKeyboardOnTap()
        .preferredColorScheme(themeController.preference.colorScheme)
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
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case .opportunity(let id):
            OpportunityDeepLinkView(
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

private struct OpportunityDeepLinkView: View {
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
                            .font(DesignTokens.Typography.section)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        BoundedBodyText(value: "Unable to resolve opportunity for id: \(id)")
                    }
                }
                .background(CyberpunkBackground())
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

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(DesignTokens.Animation.smooth) {
                        selectedTab = tab
                    }
                    SearchAdsCoordinator.shared.triggerAfterUserAction("tab_\(tab.title.lowercased())")
                } label: {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(selectedTab == tab ? DesignTokens.Colors.accentCyan : DesignTokens.Colors.textSecondary)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                            .fill(selectedTab == tab ? DesignTokens.Colors.surface2 : .clear)
                    )
                }
                .accessibilityLabel(tab.title)
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.tabBar, style: .continuous)
                .fill(DesignTokens.Colors.bg800.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.tabBar, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, DesignTokens.Spacing.l)
        .padding(.bottom, DesignTokens.Spacing.s)
    }
}
