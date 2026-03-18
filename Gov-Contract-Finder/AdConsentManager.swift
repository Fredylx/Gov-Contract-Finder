import Foundation
import Observation
import OSLog

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
@Observable
final class AdConsentManager {
    static let shared = AdConsentManager()

    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "AdConsent")

    private(set) var isSyncingConsent = false

    var shouldUseNonPersonalizedAds: Bool {
        true
    }

    func prepareOnLaunch() async {
        await syncGoogleConsentIfAvailable()
    }

    func refreshPrivacyAndConsent() async {
        await syncGoogleConsentIfAvailable()
    }

    private func syncGoogleConsentIfAvailable() async {
        guard !isSyncingConsent else { return }
        isSyncingConsent = true
        defer { isSyncingConsent = false }

        #if canImport(UserMessagingPlatform)
        let parameters = RequestParameters()

        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
                if let error {
                    self?.logger.error("UMP consent sync failed error=\(error.localizedDescription, privacy: .public)")
                } else {
                    self?.logger.debug("UMP consent sync complete")
                }
                continuation.resume()
            }
        }
        #else
        logger.debug("UMP unavailable - skipping consent sync")
        #endif
    }
}
