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

        let originalNAICS = flags.naicsPresetsEnabled
        let originalSort = flags.sortControlEnabled
        let originalDark = flags.darkModeToggleEnabled
        let originalV2 = flags.v2ShellEnabled

        flags.naicsPresetsEnabled = false
        flags.sortControlEnabled = false
        flags.darkModeToggleEnabled = false
        flags.v2ShellEnabled = false

        #expect(flags.naicsPresetsEnabled == false)
        #expect(flags.sortControlEnabled == false)
        #expect(flags.darkModeToggleEnabled == false)
        #expect(flags.v2ShellEnabled == false)

        flags.naicsPresetsEnabled = originalNAICS
        flags.sortControlEnabled = originalSort
        flags.darkModeToggleEnabled = originalDark
        flags.v2ShellEnabled = originalV2
    }
}
