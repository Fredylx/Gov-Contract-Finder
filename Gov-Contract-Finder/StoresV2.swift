import Foundation
import Observation

@MainActor
@Observable
final class WatchlistStore {
    static let shared = WatchlistStore()

    private let key = "v2.watchlist.items"
    private let defaults: UserDefaults

    var items: [WatchlistItem] = [] {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.items = load() ?? []
    }

    func contains(opportunityID: String) -> Bool {
        items.contains { $0.opportunityID == opportunityID }
    }

    func add(_ opportunity: Opportunity) {
        guard !contains(opportunityID: opportunity.id) else { return }
        let now = Date()
        let item = WatchlistItem(
            id: UUID().uuidString,
            opportunityID: opportunity.id,
            title: opportunity.title,
            agency: opportunity.agency ?? "Unknown Agency",
            postedDate: opportunity.postedDate,
            responseDate: opportunity.responseDate,
            status: .new,
            notes: "",
            createdAt: now,
            updatedAt: now
        )
        items.insert(item, at: 0)
    }

    @discardableResult
    func toggle(_ opportunity: Opportunity) -> Bool {
        if contains(opportunityID: opportunity.id) {
            remove(opportunityID: opportunity.id)
            return false
        } else {
            add(opportunity)
            return true
        }
    }

    func remove(opportunityID: String) {
        items.removeAll { $0.opportunityID == opportunityID }
    }

    func setStatus(opportunityID: String, status: WatchStatus) {
        guard let index = items.firstIndex(where: { $0.opportunityID == opportunityID }) else { return }
        items[index].status = status
        items[index].updatedAt = Date()
    }

    func setNotes(opportunityID: String, notes: String) {
        guard let index = items.firstIndex(where: { $0.opportunityID == opportunityID }) else { return }
        items[index].notes = notes
        items[index].updatedAt = Date()
    }

    func reset() {
        items = []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: key)
    }

    private func load() -> [WatchlistItem]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([WatchlistItem].self, from: data)
    }
}

@MainActor
@Observable
final class AlertsStore {
    static let shared = AlertsStore()

    private let rulesKey = "v2.alerts.rules"
    private let alertsKey = "v2.alerts.items"
    private let defaults: UserDefaults

    var rules: [AlertRule] = [] {
        didSet { persistRules() }
    }

    var items: [AlertItem] = [] {
        didSet { persistItems() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.rules = loadRules() ?? Self.defaultRules
        self.items = loadItems() ?? []
    }

    var unreadCount: Int {
        items.filter { !$0.isRead }.count
    }

    func setRuleEnabled(id: String, enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[index].enabled = enabled
    }

    func addAlert(type: AlertType, title: String, message: String, opportunityID: String? = nil) {
        let alert = AlertItem(
            id: UUID().uuidString,
            type: type,
            title: title,
            message: message,
            opportunityID: opportunityID,
            createdAt: Date(),
            isRead: false
        )
        items.insert(alert, at: 0)
    }

    func markRead(_ id: String, isRead: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isRead = isRead
    }

    func markAllRead() {
        for index in items.indices {
            items[index].isRead = true
        }
    }

    func delete(_ id: String) {
        items.removeAll { $0.id == id }
    }

    func reset() {
        rules = Self.defaultRules
        items = []
    }

    private static var defaultRules: [AlertRule] {
        [
            AlertRule(id: "rule_new", type: .newOpportunity, enabled: true, keyword: "software", createdAt: Date()),
            AlertRule(id: "rule_deadline", type: .deadline, enabled: true, keyword: "", createdAt: Date()),
            AlertRule(id: "rule_status", type: .statusChange, enabled: true, keyword: "", createdAt: Date())
        ]
    }

    private func persistRules() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        defaults.set(data, forKey: rulesKey)
    }

    private func persistItems() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: alertsKey)
    }

    private func loadRules() -> [AlertRule]? {
        guard let data = defaults.data(forKey: rulesKey) else { return nil }
        return try? JSONDecoder().decode([AlertRule].self, from: data)
    }

    private func loadItems() -> [AlertItem]? {
        guard let data = defaults.data(forKey: alertsKey) else { return nil }
        return try? JSONDecoder().decode([AlertItem].self, from: data)
    }
}

@MainActor
@Observable
final class WorkspaceStore {
    static let shared = WorkspaceStore()

    private let key = "v2.workspace.records"
    private let defaults: UserDefaults

    var records: [WorkspaceRecord] = [] {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.records = load() ?? []
    }

    func record(for opportunityID: String, fallbackTitle: String) -> WorkspaceRecord {
        if let found = records.first(where: { $0.opportunityID == opportunityID }) {
            return found
        }

        let record = WorkspaceRecord(
            id: UUID().uuidString,
            opportunityID: opportunityID,
            opportunityTitle: fallbackTitle,
            tasks: [],
            notes: [],
            documents: [],
            activity: [WorkspaceActivity(id: UUID().uuidString, text: "Workspace created", createdAt: Date())],
            updatedAt: Date()
        )
        records.insert(record, at: 0)
        return record
    }

    func upsert(_ record: WorkspaceRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.insert(record, at: 0)
        }
    }

    func reset() {
        records = []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }

    private func load() -> [WorkspaceRecord]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([WorkspaceRecord].self, from: data)
    }
}
