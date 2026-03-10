import Foundation
import OSLog

/// A provider for retrieving the SAM API key from environment variables.
public struct APIKeyProvider {
    private static let logger = Logger(subsystem: "Gov-Contract-Finder", category: "APIKeyProvider")

    /// Returns the SAM API key from process environment variable `SAM_API_KEY`.
    public static func samKey() -> String? {
        if let envKey = ProcessInfo.processInfo.environment["SAM_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !envKey.isEmpty,
           !envKey.hasPrefix("REPLACE_WITH") {
            if DebugSettings.shared.isEnabled {
                logger.debug("SAM API key found in environment")
            }
            return envKey
        }

        if DebugSettings.shared.isEnabled {
            logger.error("SAM API key not found")
        }
        return nil
    }
}
