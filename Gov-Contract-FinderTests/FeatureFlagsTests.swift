//
//  FeatureFlagsTests.swift
//  Gov-Contract-FinderTests
//
//  Created by Fredy lopez on 2/12/26.
//

import Foundation
import Testing
@testable import Gov_Contract_Finder

struct FeatureFlagsTests {
    @Test func togglesPersistValues() {
        let flags = FeatureFlags.shared

        let originalSearchAds = flags.searchAdsEnabled
        let originalWalkthrough = flags.ccmWalkthroughEnabled
        let originalLiveAlerts = flags.liveAlertsRefreshEnabled

        flags.searchAdsEnabled = false
        flags.ccmWalkthroughEnabled = true
        flags.liveAlertsRefreshEnabled = true

        #expect(flags.searchAdsEnabled == false)
        #expect(flags.ccmWalkthroughEnabled == true)
        #expect(flags.liveAlertsRefreshEnabled == true)

        flags.searchAdsEnabled = originalSearchAds
        flags.ccmWalkthroughEnabled = originalWalkthrough
        flags.liveAlertsRefreshEnabled = originalLiveAlerts
    }
}
