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
                        workspaceStore: workspaceStore
                    )
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
                    AlertsViewV2(alertsStore: alertsStore)
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
        }
        .dismissKeyboardOnTap()
        .preferredColorScheme(themeController.preferenceV2.colorScheme)
        .task {
            await tipJarStore.startIfNeeded()
            await adConsentManager.prepareOnLaunch()
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
