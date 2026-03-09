import Foundation
import OSLog

@MainActor
enum AppConfigValidator {
    private static let logger = Logger(subsystem: "Gov-Contract-Finder", category: "Config")

    static func validateAtLaunch() {
        let gadAppID = value(for: "GADApplicationIdentifier")
        let interstitialID = value(for: "ADMOB_SEARCH_INTERSTITIAL_AD_UNIT_ID")
        let samKey = value(for: "SAM_API_KEY")

        #if DEBUG
        validateDebug(gadAppID: gadAppID, interstitialID: interstitialID, samKey: samKey)
        #else
        validateRelease(gadAppID: gadAppID, interstitialID: interstitialID, samKey: samKey)
        #endif
    }

    private static func validateDebug(gadAppID: String, interstitialID: String, samKey: String) {
        if gadAppID.hasPrefix("REPLACE_WITH") || interstitialID.hasPrefix("REPLACE_WITH") {
            assertionFailure("AdMob config placeholders are still present in Debug. Check xcconfig wiring.")
        }

        if samKey.isEmpty || samKey.hasPrefix("REPLACE_WITH") {
            logger.warning("SAM API key is missing in Debug configuration")
        }
    }

    private static func validateRelease(gadAppID: String, interstitialID: String, samKey: String) {
        let isUsingTestAdIDs = gadAppID == "ca-app-pub-3940256099942544~1458002511"
            || interstitialID == "ca-app-pub-3940256099942544/4411468910"

        if isUsingTestAdIDs {
            logger.fault("Release build is using Google test ad IDs")
        }

        if samKey.isEmpty || samKey.hasPrefix("REPLACE_WITH") {
            logger.fault("Release build SAM API key is missing or placeholder")
        }
    }

    private static func value(for key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
