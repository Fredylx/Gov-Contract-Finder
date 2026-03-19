import Foundation
import Observation

@Observable
final class FeatureFlags {
    static let shared = FeatureFlags()

    private let searchAdsKey = "feature.searchAds"
    private let ccmWalkthroughKey = "feature.ccmWalkthrough"
    private let liveAlertsRefreshKey = "feature.liveAlertsRefresh"

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
