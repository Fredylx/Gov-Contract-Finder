import Foundation
import Testing
@testable import Gov_Contract_Finder

@MainActor
struct AlertRefreshCoordinatorTests {
    @Test func searchAdsCoordinatorAppliesPerSearchDetailGrace() async {
        let coordinator = SearchAdsCoordinator.shared
        let originalSearchAdsEnabled = FeatureFlags.shared.searchAdsEnabled
        FeatureFlags.shared.searchAdsEnabled = true
        coordinator.resetForTesting()
        coordinator.setDetailInterstitialThresholdForTesting(1)
        defer {
            coordinator.resetForTesting()
            FeatureFlags.shared.searchAdsEnabled = originalSearchAdsEnabled
        }

        coordinator.notifySearchCompleted()

        let first = await coordinator.registerDetailOpenAndMaybeShowInterstitial()
        let second = await coordinator.registerDetailOpenAndMaybeShowInterstitial()
        let third = await coordinator.registerDetailOpenAndMaybeShowInterstitial()

        #expect(first == .skippedPerSearchGrace(remaining: 1))
        #expect(second == .skippedPerSearchGrace(remaining: 0))

        if case .skippedPerSearchGrace = third {
            Issue.record("Expected the third detail open to leave the grace period.")
        }
    }

    @Test func alertRefreshCoordinatorCreatesAlertsForUnseenSAMMatches() async {
        let suiteName = "alert-refresh-new-opportunities-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let opportunity = makeAlertOpportunity(id: "sam-opp-1", responseDate: "03/24/2026")
        let repository = MockOpportunityRepository(resultsByQuery: ["software": [opportunity]])
        let coordinator = AlertRefreshCoordinator(repository: repository, defaults: defaults)
        let alertsStore = AlertsStore(defaults: defaults)
        let watchlistStore = WatchlistStore(defaults: defaults)
        let workspaceStore = WorkspaceStore(defaults: defaults)
        let now = fixedDate(month: 3, day: 17, year: 2026)

        await coordinator.refreshNow(
            alertsStore: alertsStore,
            watchlistStore: watchlistStore,
            workspaceStore: workspaceStore,
            now: now
        )

        #expect(alertsStore.items.count == 1)
        #expect(alertsStore.items.first?.type == .newOpportunity)
        #expect(alertsStore.items.first?.snapshot?.id == opportunity.id)
        #expect(coordinator.lastSuccessfulRefreshAt == now)

        await coordinator.refreshNow(
            alertsStore: alertsStore,
            watchlistStore: watchlistStore,
            workspaceStore: workspaceStore,
            now: now.addingTimeInterval(3600)
        )

        #expect(alertsStore.items.count == 1)
        #expect(repository.searchCallCount == 2)
    }

    @Test func alertRefreshCoordinatorDeduplicatesDeadlineMilestonesAcrossStores() async {
        let suiteName = "alert-refresh-deadlines-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let repository = MockOpportunityRepository(resultsByQuery: [:])
        let coordinator = AlertRefreshCoordinator(repository: repository, defaults: defaults)
        let alertsStore = AlertsStore(defaults: defaults)
        let watchlistStore = WatchlistStore(defaults: defaults)
        let workspaceStore = WorkspaceStore(defaults: defaults)
        let now = fixedDate(month: 3, day: 17, year: 2026)
        let sharedOpportunity = makeAlertOpportunity(id: "due-opp-1", responseDate: "03/24/2026")

        watchlistStore.add(sharedOpportunity)
        _ = workspaceStore.record(for: sharedOpportunity)

        await coordinator.refreshNow(
            alertsStore: alertsStore,
            watchlistStore: watchlistStore,
            workspaceStore: workspaceStore,
            now: now
        )

        #expect(alertsStore.items.count == 1)
        #expect(alertsStore.items.first?.type == .deadline)
        #expect(alertsStore.items.first?.opportunityID == sharedOpportunity.id)

        await coordinator.refreshNow(
            alertsStore: alertsStore,
            watchlistStore: watchlistStore,
            workspaceStore: workspaceStore,
            now: now
        )

        #expect(alertsStore.items.count == 1)
    }

    @Test func alertRefreshCoordinatorThrottlesForegroundRefreshesWithinFifteenMinutes() async {
        let suiteName = "alert-refresh-throttle-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let originalLiveAlertsEnabled = FeatureFlags.shared.liveAlertsRefreshEnabled
        FeatureFlags.shared.liveAlertsRefreshEnabled = true
        defer {
            FeatureFlags.shared.liveAlertsRefreshEnabled = originalLiveAlertsEnabled
        }

        let repository = MockOpportunityRepository(resultsByQuery: ["software": [makeAlertOpportunity(id: "sam-opp-2", responseDate: "03/26/2026")]])
        let coordinator = AlertRefreshCoordinator(repository: repository, defaults: defaults)
        let alertsStore = AlertsStore(defaults: defaults)
        let watchlistStore = WatchlistStore(defaults: defaults)
        let workspaceStore = WorkspaceStore(defaults: defaults)
        let firstActiveAt = fixedDate(month: 3, day: 17, year: 2026)

        await coordinator.handleAppDidBecomeActive(
            alertsStore: alertsStore,
            watchlistStore: watchlistStore,
            workspaceStore: workspaceStore,
            now: firstActiveAt
        )

        await coordinator.handleAppDidBecomeActive(
            alertsStore: alertsStore,
            watchlistStore: watchlistStore,
            workspaceStore: workspaceStore,
            now: firstActiveAt.addingTimeInterval(5 * 60)
        )

        #expect(repository.searchCallCount == 1)
    }
}

@MainActor
private final class MockOpportunityRepository: OpportunityRepository {
    private let resultsByQuery: [String: [Opportunity]]
    private(set) var searchCallCount = 0

    init(resultsByQuery: [String: [Opportunity]]) {
        self.resultsByQuery = resultsByQuery
    }

    func search(filters: OpportunitySearchFiltersV2, limit: Int, offset: Int) async throws -> OpportunitySearchPageV2 {
        searchCallCount += 1
        let opportunities = Array((resultsByQuery[filters.query] ?? []).prefix(limit))
        return OpportunitySearchPageV2(
            opportunities: opportunities,
            totalRecords: opportunities.count
        )
    }
}

private func fixedDate(month: Int, day: Int, year: Int) -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return calendar.date(from: DateComponents(year: year, month: month, day: day))!
}

private func makeAlertOpportunity(id: String, responseDate: String) -> Opportunity {
    Opportunity(
        id: id,
        title: "Opportunity \(id)",
        agency: "Agency",
        postedDate: "03/15/2026",
        description: "Description",
        solicitationNumber: "SOL-\(id)",
        fullParentPathName: "Agency/Division",
        fullParentPathCode: "AGY/\(id)",
        office: "Office",
        uiLink: "https://sam.gov/opp/\(id)",
        additionalInfoLink: "https://example.com/\(id)",
        resourceLinks: ["https://example.com/\(id).pdf"],
        responseDate: responseDate,
        setAsideCode: "SBA",
        naicsCode: "541511",
        naicsDescription: "Custom Computer Programming Services",
        contactEmail: "\(id)@example.com",
        contactName: "Contact \(id)",
        contactPhone: "555-0100",
        contacts: [
            Opportunity.Contact(
                id: "contact-\(id)",
                type: "primary",
                title: "Contracting Officer",
                fullName: "Contact \(id)",
                email: "\(id)@example.com",
                phone: "555-0100",
                fax: nil
            )
        ]
    )
}
