import Foundation
import Observation

struct AlertRefreshState: Codable, Equatable {
    var lastSuccessfulRefreshAt: Date?
    var seenNoticeIDsByRuleID: [String: Set<String>] = [:]
    var emittedDeadlineMilestones: Set<String> = []
}

@MainActor
@Observable
final class AlertRefreshCoordinator {
    private static let refreshStateKey = "v2.alerts.refreshState"
    private let defaults: UserDefaults
    private let repository: OpportunityRepository
    private let refreshInterval: TimeInterval = 15 * 60

    var state: AlertRefreshState {
        didSet { persist() }
    }

    private(set) var isRefreshing = false
    private var hasHandledFirstActiveThisSession = false

    init(repository: OpportunityRepository, defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults
        self.state = Self.load(from: defaults, key: Self.refreshStateKey)
    }

    convenience init(defaults: UserDefaults = .standard) {
        self.init(repository: SAMOpportunityRepository(), defaults: defaults)
    }

    var lastSuccessfulRefreshAt: Date? {
        state.lastSuccessfulRefreshAt
    }

    func handleAppDidBecomeActive(
        alertsStore: AlertsStore,
        watchlistStore: WatchlistStore,
        workspaceStore: WorkspaceStore,
        now: Date = Date()
    ) async {
        guard FeatureFlags.shared.liveAlertsRefreshEnabled else { return }
        guard !isRefreshing else { return }

        let shouldForceRefresh = !hasHandledFirstActiveThisSession
        hasHandledFirstActiveThisSession = true

        guard shouldForceRefresh || shouldRefresh(at: now) else { return }
        await refreshNow(
            alertsStore: alertsStore,
            watchlistStore: watchlistStore,
            workspaceStore: workspaceStore,
            now: now
        )
    }

    func refreshNow(
        alertsStore: AlertsStore,
        watchlistStore: WatchlistStore,
        workspaceStore: WorkspaceStore,
        now: Date = Date()
    ) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        await refreshNewOpportunityAlerts(alertsStore: alertsStore, now: now)
        refreshDeadlineAlerts(
            alertsStore: alertsStore,
            watchlistStore: watchlistStore,
            workspaceStore: workspaceStore,
            now: now
        )
        state.lastSuccessfulRefreshAt = now
    }

    private func shouldRefresh(at now: Date) -> Bool {
        guard let lastSuccessfulRefreshAt = state.lastSuccessfulRefreshAt else {
            return true
        }
        return now.timeIntervalSince(lastSuccessfulRefreshAt) >= refreshInterval
    }

    private func refreshNewOpportunityAlerts(alertsStore: AlertsStore, now: Date) async {
        let enabledKeywordRules = alertsStore
            .enabledRules(for: .newOpportunity)
            .filter { !$0.keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard !enabledKeywordRules.isEmpty else { return }

        let postedTo = Self.apiDateString(from: now)
        let postedFrom: String = {
            if let lastSuccessfulRefreshAt = state.lastSuccessfulRefreshAt,
               let resumedWindow = Calendar.current.date(byAdding: .day, value: -1, to: lastSuccessfulRefreshAt) {
                return Self.apiDateString(from: resumedWindow)
            }

            let initialWindow = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now
            return Self.apiDateString(from: initialWindow)
        }()

        for rule in enabledKeywordRules {
            var filters = OpportunitySearchFiltersV2()
            filters.query = rule.keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            filters.postedFrom = postedFrom
            filters.postedTo = postedTo
            filters.sort = "postedDate"
            filters.order = "desc"

            do {
                let page = try await repository.search(filters: filters, limit: 25, offset: 0)
                let fetchedIDs = Set(page.opportunities.map(\.id))
                var seenIDs = state.seenNoticeIDsByRuleID[rule.id] ?? []
                var newAlertCount = 0

                for opportunity in page.opportunities where !seenIDs.contains(opportunity.id) {
                    guard newAlertCount < 3 else { break }
                    alertsStore.addAlert(
                        type: .newOpportunity,
                        title: "New Match for \(filters.query)",
                        message: opportunity.title,
                        opportunityID: opportunity.id,
                        snapshot: SavedOpportunitySnapshot(opportunity: opportunity)
                    )
                    newAlertCount += 1
                }

                seenIDs.formUnion(fetchedIDs)
                state.seenNoticeIDsByRuleID[rule.id] = seenIDs
            } catch {
                continue
            }
        }
    }

    private func refreshDeadlineAlerts(
        alertsStore: AlertsStore,
        watchlistStore: WatchlistStore,
        workspaceStore: WorkspaceStore,
        now: Date
    ) {
        guard alertsStore.isAnyRuleEnabled(for: .deadline) else { return }

        var snapshotsByOpportunityID: [String: SavedOpportunitySnapshot] = [:]

        for item in watchlistStore.items {
            let snapshot = item.resolvedSnapshot
            snapshotsByOpportunityID[snapshot.id] = snapshot
        }

        for record in workspaceStore.records {
            guard let snapshot = record.snapshot else { continue }
            if snapshotsByOpportunityID[snapshot.id] == nil {
                snapshotsByOpportunityID[snapshot.id] = snapshot
            }
        }

        for snapshot in snapshotsByOpportunityID.values {
            guard let responseDate = snapshot.responseDate,
                  let deadline = Self.deadlineDate(from: responseDate) else {
                continue
            }

            let daysUntilDeadline = Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: now),
                to: Calendar.current.startOfDay(for: deadline)
            ).day ?? -1

            guard let milestone = Self.deadlineMilestone(for: daysUntilDeadline) else { continue }

            let milestoneKey = "\(snapshot.id)|\(milestone)"
            guard !state.emittedDeadlineMilestones.contains(milestoneKey) else { continue }

            alertsStore.addAlert(
                type: .deadline,
                title: Self.deadlineAlertTitle(for: milestone),
                message: snapshot.title,
                opportunityID: snapshot.id,
                snapshot: snapshot
            )
            state.emittedDeadlineMilestones.insert(milestoneKey)
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Self.refreshStateKey)
    }

    private static func load(from defaults: UserDefaults, key: String) -> AlertRefreshState {
        guard let data = defaults.data(forKey: key),
              let state = try? JSONDecoder().decode(AlertRefreshState.self, from: data) else {
            return AlertRefreshState()
        }
        return state
    }

    private static func apiDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }

    private static func deadlineDate(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.date(from: value)
    }

    private static func deadlineMilestone(for daysUntilDeadline: Int) -> Int? {
        switch daysUntilDeadline {
        case 7, 3, 1, 0:
            return daysUntilDeadline
        default:
            return nil
        }
    }

    private static func deadlineAlertTitle(for milestone: Int) -> String {
        switch milestone {
        case 0:
            return "Response deadline is today"
        case 1:
            return "Response deadline in 1 day"
        default:
            return "Response deadline in \(milestone) days"
        }
    }
}
