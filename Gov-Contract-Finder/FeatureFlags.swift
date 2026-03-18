import Foundation
import Observation

@Observable
final class FeatureFlags {
    static let shared = FeatureFlags()

    private let naicsPresetsKey = "feature.naicsPresets"
    private let sortControlKey = "feature.sortControl"
    private let darkModeToggleKey = "feature.darkModeToggle"
    private let v2ShellKey = "feature.v2Shell"
    private let searchAdsKey = "feature.searchAds"
    private let ccmWalkthroughKey = "feature.ccmWalkthrough"
    private let liveAlertsRefreshKey = "feature.liveAlertsRefresh"

    var naicsPresetsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: naicsPresetsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: naicsPresetsKey) }
    }

    var sortControlEnabled: Bool {
        get { UserDefaults.standard.object(forKey: sortControlKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: sortControlKey) }
    }

    var darkModeToggleEnabled: Bool {
        get { UserDefaults.standard.object(forKey: darkModeToggleKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: darkModeToggleKey) }
    }

    var v2ShellEnabled: Bool {
        get {
            if let stored = UserDefaults.standard.object(forKey: v2ShellKey) as? Bool {
                return stored
            }
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        set {
            UserDefaults.standard.set(newValue, forKey: v2ShellKey)
        }
    }

    var searchAdsEnabled: Bool {
        get {
            if let stored = UserDefaults.standard.object(forKey: searchAdsKey) as? Bool {
                return stored
            }
            return true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: searchAdsKey)
        }
    }

    var ccmWalkthroughEnabled: Bool {
        get {
            if let stored = UserDefaults.standard.object(forKey: ccmWalkthroughKey) as? Bool {
                return stored
            }
            return false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ccmWalkthroughKey)
        }
    }

    var liveAlertsRefreshEnabled: Bool {
        get {
            if let stored = UserDefaults.standard.object(forKey: liveAlertsRefreshKey) as? Bool {
                return stored
            }
            return false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: liveAlertsRefreshKey)
        }
    }
}
