import Foundation
import OSLog

/// A provider for retrieving the SAM API key from environment variables or Info.plist.
public struct APIKeyProvider {
    private static let logger = Logger(subsystem: "Gov-Contract-Finder", category: "APIKeyProvider")

    /// Returns the SAM API key by checking the process environment variable `SAM_API_KEY` first,
    /// then checking the app's Info.plist for the `SAM_API_KEY` key.
    ///
    /// - Returns: An optional `String` containing the API key if found and non-empty, otherwise `nil`.
    public static func samKey() -> String? {
        // Check environment variable
        if let envKey = ProcessInfo.processInfo.environment["SAM_API_KEY"], !envKey.isEmpty {
            if DebugSettings.shared.isEnabled {
                logger.debug("SAM API key found in environment")
            }
            return envKey
        }

        // Check Info.plist
        if let infoDict = Bundle.main.infoDictionary,
           let plistKey = infoDict["SAM_API_KEY"] as? String,
           !plistKey.isEmpty {
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
}
