import Foundation
import OSLog

/// A provider for retrieving the SAM API key from build/runtime configuration.
public struct APIKeyProvider {
    private static let logger = Logger(subsystem: "Gov-Contract-Finder", category: "APIKeyProvider")

    /// Returns the SAM API key from:
    /// 1) process env `SAM_API_KEY` (CI / scheme override)
    /// 2) bundled Info.plist `SAM_API_KEY` injected from xcconfig
    public static func samKey() -> String? {
        if let envKey = sanitized(ProcessInfo.processInfo.environment["SAM_API_KEY"]) {
            if DebugSettings.shared.isEnabled {
                logger.debug("SAM API key found in environment")
            }
            return envKey
        }

        if let plistKey = sanitized(Bundle.main.object(forInfoDictionaryKey: "SAM_API_KEY") as? String) {
            if DebugSettings.shared.isEnabled {
                logger.debug("SAM API key found in Info.plist")
            }
            return plistKey
        }

        if DebugSettings.shared.isEnabled {
            logger.error("SAM API key not found")
        }
        return nil
    }

    private static func sanitized(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("REPLACE_WITH") else {
            return nil
        }
        return value
    }
}
