import SwiftUI

struct RootView: View {
    @State private var featureFlags = FeatureFlags.shared

    var body: some View {
        Group {
            if featureFlags.v2ShellEnabled {
                RootViewV2()
            } else {
                LegacyRootView()
            }
        }
    }
}

private struct LegacyRootView: View {
    @State private var themeController = ThemeController()
    @State private var featureFlags = FeatureFlags.shared

    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            SettingsView(themeController: themeController)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(DesignSystem.Colors.accentTeal)
        .preferredColorScheme(featureFlags.darkModeToggleEnabled ? themeController.preference.colorScheme : nil)
    }
}
