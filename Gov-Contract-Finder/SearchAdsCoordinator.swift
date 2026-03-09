import Foundation
import OSLog
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

enum SearchAdPresentationOutcome: Equatable {
    case shown
    case skippedDisabled
    case skippedCooldown(remainingSeconds: Int)
    case skippedSessionCap(maxPerSession: Int)
    case skippedNotReady
    case skippedSdkUnavailable
    case failed(message: String)

    var shortDescription: String {
        switch self {
        case .shown:
            return "shown"
        case .skippedDisabled:
            return "skipped_disabled"
        case .skippedCooldown(let remainingSeconds):
            return "skipped_cooldown_\(remainingSeconds)s"
        case .skippedSessionCap(let maxPerSession):
            return "skipped_session_cap_\(maxPerSession)"
        case .skippedNotReady:
            return "skipped_not_ready"
        case .skippedSdkUnavailable:
            return "skipped_sdk_unavailable"
        case .failed(let message):
            return "failed_\(message)"
        }
    }
}

@MainActor
private final class SearchAdGatekeeper {
    private let minSecondsBetweenShows: TimeInterval
    private let maxShowsPerSession: Int
    private let minActionsBetweenShows: Int

    private(set) var showsThisSession: Int = 0
    private var lastShowAt: Date?
    private var actionsSinceLastShow: Int = 0

    init(
        minSecondsBetweenShows: TimeInterval,
        maxShowsPerSession: Int,
        minActionsBetweenShows: Int
    ) {
        self.minSecondsBetweenShows = minSecondsBetweenShows
        self.maxShowsPerSession = maxShowsPerSession
        self.minActionsBetweenShows = minActionsBetweenShows
    }

    func registerAction() {
        actionsSinceLastShow += 1
    }

    func evaluate(
        ignoreCooldown: Bool,
        ignoreActionCadence: Bool,
        ignoreSessionCap: Bool,
        now: Date = Date()
    ) -> SearchAdPresentationOutcome? {
        if !ignoreSessionCap && showsThisSession >= maxShowsPerSession {
            return .skippedSessionCap(maxPerSession: maxShowsPerSession)
        }

        if !ignoreActionCadence && showsThisSession > 0 && actionsSinceLastShow < minActionsBetweenShows {
            return .skippedNotReady
        }

        if ignoreCooldown {
            return nil
        }

        guard let lastShowAt else {
            return nil
        }

        let elapsed = now.timeIntervalSince(lastShowAt)
        if elapsed < minSecondsBetweenShows {
            let remaining = Int((minSecondsBetweenShows - elapsed).rounded(.up))
            return .skippedCooldown(remainingSeconds: max(1, remaining))
        }

        return nil
    }

    func markShown(now: Date = Date()) {
        lastShowAt = now
        showsThisSession += 1
        actionsSinceLastShow = 0
    }
}

@MainActor
final class SearchAdsCoordinator: NSObject {
    static let shared = SearchAdsCoordinator()

    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "SearchAds")
    private let gatekeeper = SearchAdGatekeeper(
        minSecondsBetweenShows: 20,
        maxShowsPerSession: 30,
        minActionsBetweenShows: 2
    )

    private var hasInitialized = false
    private var isPreloading = false
    private var isPresenting = false

    #if canImport(GoogleMobileAds)
    private var interstitial: InterstitialAd?
    private var presentationContinuation: CheckedContinuation<SearchAdPresentationOutcome, Never>?
    #endif

    private override init() {
        super.init()
    }

    func configureOnLaunchIfNeeded() {
        guard FeatureFlags.shared.searchAdsEnabled else {
            debugLog("configure skipped feature disabled")
            return
        }
        guard !hasInitialized else { return }

        hasInitialized = true

        #if canImport(GoogleMobileAds)
        MobileAds.shared.start()
        debugLog("sdk initialized appID=\(self.applicationIDSummary())")
        #else
        debugLog("sdk unavailable (GoogleMobileAds not linked)")
        #endif

        preloadSearchInterstitial()
    }

    func preloadSearchInterstitial() {
        guard FeatureFlags.shared.searchAdsEnabled else { return }
        guard hasInitialized else {
            configureOnLaunchIfNeeded()
            return
        }

        #if canImport(GoogleMobileAds)
        guard !isPreloading else { return }
        guard interstitial == nil else { return }

        isPreloading = true
        let startedAt = Date()
        let adUnitID = searchInterstitialAdUnitID()
        let request = buildAdRequest()
        debugLog("preload start adUnit=\(adUnitID)")

        InterstitialAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPreloading = false
                let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)

                if let error {
                    self.debugLog("preload failed elapsedMs=\(elapsedMs) error=\"\(error.localizedDescription)\"")
                    return
                }

                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
                self.debugLog("preload success elapsedMs=\(elapsedMs)")
            }
        }
        #else
        debugLog("preload skipped sdk unavailable")
        #endif
    }

    func showSearchInterstitialIfAllowed() async -> SearchAdPresentationOutcome {
        await showInterstitialIfAllowed(
            reason: "search",
            ignoreCooldown: false,
            ignoreActionCadence: false,
            ignoreSessionCap: false,
            registerAction: true
        )
    }

    func showSearchInterstitialForSearchTap() async -> SearchAdPresentationOutcome {
        await showInterstitialIfAllowed(
            reason: "search_tap",
            ignoreCooldown: true,
            ignoreActionCadence: true,
            ignoreSessionCap: true,
            registerAction: false
        )
    }

    func triggerAfterUserAction(_ action: String) {
        Task { @MainActor in
            _ = await showInterstitialIfAllowed(
                reason: action,
                ignoreCooldown: false,
                ignoreActionCadence: false,
                ignoreSessionCap: false,
                registerAction: true
            )
        }
    }

    func showSupportAdAsGift() async -> SearchAdPresentationOutcome {
        await showInterstitialIfAllowed(
            reason: "support_gift",
            ignoreCooldown: true,
            ignoreActionCadence: true,
            ignoreSessionCap: false,
            registerAction: false
        )
    }

    private func showInterstitialIfAllowed(
        reason: String,
        ignoreCooldown: Bool,
        ignoreActionCadence: Bool,
        ignoreSessionCap: Bool,
        registerAction: Bool
    ) async -> SearchAdPresentationOutcome {
        guard FeatureFlags.shared.searchAdsEnabled else {
            return .skippedDisabled
        }

        configureOnLaunchIfNeeded()

        if registerAction {
            gatekeeper.registerAction()
        }

        if let denied = gatekeeper.evaluate(
            ignoreCooldown: ignoreCooldown,
            ignoreActionCadence: ignoreActionCadence,
            ignoreSessionCap: ignoreSessionCap
        ) {
            debugLog("show skipped reason=\(reason) gate=\(denied.shortDescription)")
            preloadSearchInterstitial()
            return denied
        }

        #if canImport(GoogleMobileAds)
        if isPresenting {
            debugLog("show skipped reason=\(reason) already presenting")
            return .skippedNotReady
        }

        guard let interstitial else {
            debugLog("show skipped reason=\(reason) not ready")
            preloadSearchInterstitial()
            return .skippedNotReady
        }

        guard let rootViewController = Self.topMostViewController() else {
            debugLog("show failed reason=\(reason) missing root view controller")
            preloadSearchInterstitial()
            return .failed(message: "missing_root_view_controller")
        }

        isPresenting = true
        self.interstitial = nil
        interstitial.fullScreenContentDelegate = self
        debugLog("show start reason=\(reason)")

        let outcome = await withCheckedContinuation { (continuation: CheckedContinuation<SearchAdPresentationOutcome, Never>) in
            self.presentationContinuation = continuation
            interstitial.present(from: rootViewController)
        }
        isPresenting = false

        if case .shown = outcome {
            gatekeeper.markShown()
        }

        debugLog("show end reason=\(reason) outcome=\(outcome.shortDescription)")
        preloadSearchInterstitial()
        return outcome
        #else
        debugLog("show skipped reason=\(reason) sdk unavailable")
        return .skippedSdkUnavailable
        #endif
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        guard DebugSettings.shared.isEnabled else { return }
        logger.debug("\(message, privacy: .public)")
        #endif
    }

    private func searchInterstitialAdUnitID() -> String {
        let configured = (Bundle.main.object(forInfoDictionaryKey: "ADMOB_SEARCH_INTERSTITIAL_AD_UNIT_ID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let configured, !configured.isEmpty {
            return configured
        }

        // Google sample interstitial test unit for iOS.
        return "ca-app-pub-3940256099942544/4411468910"
    }

    #if canImport(GoogleMobileAds)
    private func buildAdRequest() -> Request {
        let request = Request()

        if AdConsentManager.shared.shouldUseNonPersonalizedAds {
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
            debugLog("using non-personalized ad request")
        } else {
            debugLog("using personalized ad request")
        }

        return request
    }
    #endif

    private func applicationIDSummary() -> String {
        let value = (Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if value.isEmpty { return "missing" }
        return value
    }

    @MainActor
    private static func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let resolvedBase: UIViewController? = {
            if let base { return base }
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: \.isKeyWindow)?
                .rootViewController
        }()

        if let navigationController = resolvedBase as? UINavigationController {
            return topMostViewController(base: navigationController.visibleViewController)
        }
        if let tabController = resolvedBase as? UITabBarController, let selected = tabController.selectedViewController {
            return topMostViewController(base: selected)
        }
        if let presented = resolvedBase?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return resolvedBase
    }
}

#if canImport(GoogleMobileAds)
extension SearchAdsCoordinator: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard let continuation = presentationContinuation else { return }
        presentationContinuation = nil
        continuation.resume(returning: .shown)
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        guard let continuation = presentationContinuation else { return }
        presentationContinuation = nil
        continuation.resume(returning: .failed(message: error.localizedDescription))
    }
}
#endif
