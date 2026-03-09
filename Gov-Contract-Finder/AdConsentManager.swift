import Foundation
import Observation
import OSLog
import AppTrackingTransparency

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
@Observable
final class AdConsentManager {
    static let shared = AdConsentManager()

    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "AdConsent")
    private let personalizedAdsKey = "settings.personalizedAdsEnabled"

    private(set) var isSyncingConsent = false

    var personalizedAdsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: personalizedAdsKey) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: personalizedAdsKey) }
    }

    var trackingStatus: ATTrackingManager.AuthorizationStatus {
        if #available(iOS 14, *) {
            return ATTrackingManager.trackingAuthorizationStatus
        }
        return .authorized
    }

    var trackingStatusText: String {
        switch trackingStatus {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }

    var shouldUseNonPersonalizedAds: Bool {
        guard personalizedAdsEnabled else { return true }
        if #available(iOS 14, *) {
            return ATTrackingManager.trackingAuthorizationStatus != .authorized
        }
        return false
    }

    func prepareOnLaunch() async {
        await syncGoogleConsentIfAvailable()
    }

    func setPersonalizedAdsEnabled(_ enabled: Bool) async {
        personalizedAdsEnabled = enabled

        if enabled {
            _ = await requestTrackingAuthorizationIfNeeded()
        }

        await syncGoogleConsentIfAvailable()
    }

    func requestTrackingAuthorizationIfNeeded() async -> ATTrackingManager.AuthorizationStatus {
        guard #available(iOS 14, *) else { return .authorized }
        let current = ATTrackingManager.trackingAuthorizationStatus
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func refreshPrivacyAndConsent() async {
        if personalizedAdsEnabled {
            _ = await requestTrackingAuthorizationIfNeeded()
        }
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
