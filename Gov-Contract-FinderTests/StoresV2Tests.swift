import Foundation
import Testing
@testable import Gov_Contract_Finder

@MainActor
struct StoresV2Tests {
    @Test func watchlistStorePersistsSnapshotsAcrossInstances() {
        let suiteName = "watchlist-store-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = WatchlistStore(defaults: defaults)
        let opportunity = makeOpportunity(id: "opp-1")
        store.add(opportunity)

        let reloaded = WatchlistStore(defaults: defaults)
        let saved = reloaded.items.first!

        #expect(reloaded.items.count == 1)
        #expect(saved.opportunityID == "opp-1")
        #expect(reloaded.contains(opportunityID: "opp-1"))
        #expect(saved.snapshot?.solicitationNumber == opportunity.solicitationNumber)
        #expect(saved.snapshot?.uiLink == opportunity.uiLink)
        #expect(saved.snapshot?.naicsCode == opportunity.naicsCode)
        #expect(saved.snapshot?.contacts.count == opportunity.contacts.count)
        #expect(saved.asOpportunity.contactEmail == opportunity.contactEmail)
        #expect(saved.asOpportunity.additionalInfoLink == opportunity.additionalInfoLink)
    }

    @Test func watchlistStoreRemoveAllClearsPersistedItems() {
        let suiteName = "watchlist-remove-all-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = WatchlistStore(defaults: defaults)
        let opportunities = [
            makeOpportunity(id: "opp-1", title: "First Opportunity"),
            makeOpportunity(id: "opp-2", title: "Second Opportunity")
        ]

        for opportunity in opportunities {
            store.add(opportunity)
        }

        #expect(store.items.count == 2)

        store.removeAll()

        #expect(store.items.isEmpty)

        let reloaded = WatchlistStore(defaults: defaults)
        #expect(reloaded.items.isEmpty)
    }

    @Test func watchlistStoreLegacyItemsStillResolveOpportunitySnapshot() throws {
        let suiteName = "watchlist-legacy-store-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let legacyItem = LegacyWatchlistItemRecord(
            id: "legacy-item-1",
            opportunityID: "legacy-opp-1",
            title: "Legacy Opportunity",
            agency: "Legacy Agency",
            postedDate: "03/01/2026",
            responseDate: "03/15/2026",
            status: .reviewing,
            notes: "Stored before snapshots",
            createdAt: Date(timeIntervalSince1970: 100),
            updatedAt: Date(timeIntervalSince1970: 200)
        )

        let data = try JSONEncoder().encode([legacyItem])
        defaults.set(data, forKey: "v2.watchlist.items")

        let store = WatchlistStore(defaults: defaults)
        let item = store.items.first!

        #expect(item.snapshot == nil)
        #expect(item.asOpportunity.id == legacyItem.opportunityID)
        #expect(item.asOpportunity.title == legacyItem.title)
        #expect(item.asOpportunity.description == legacyItem.notes)
    }

    @Test func alertsStoreMarkAllReadUpdatesUnreadCount() {
        let suiteName = "alerts-store-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AlertsStore(defaults: defaults)
        store.addAlert(type: .newOpportunity, title: "A", message: "A")
        store.addAlert(type: .deadline, title: "B", message: "B")

        #expect(store.unreadCount == 2)
        store.markAllRead()
        #expect(store.unreadCount == 0)

        let reloaded = AlertsStore(defaults: defaults)
        #expect(reloaded.unreadCount == 0)
    }

    @Test func alertsStoreClearAllRemovesPersistedItemsButKeepsRules() {
        let suiteName = "alerts-store-clear-all-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AlertsStore(defaults: defaults)
        let originalRuleCount = store.rules.count
        store.addAlert(type: .newOpportunity, title: "A", message: "A")
        store.addAlert(type: .deadline, title: "B", message: "B")

        #expect(store.items.count == 2)

        store.clearAll()

        #expect(store.items.isEmpty)
        #expect(store.rules.count == originalRuleCount)

        let reloaded = AlertsStore(defaults: defaults)
        #expect(reloaded.items.isEmpty)
        #expect(reloaded.rules.count == originalRuleCount)
    }

    @Test func alertsStoreAddAlertIfEnabledRespectsRuleState() {
        let suiteName = "alerts-store-gated-alerts-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AlertsStore(defaults: defaults)
        store.rules.removeAll { $0.type == .statusChange }

        let blocked = store.addAlertIfEnabled(
            type: .statusChange,
            title: "Blocked",
            message: "Should not be added"
        )
        #expect(blocked == false)
        #expect(store.items.isEmpty)

        store.rules.append(
            AlertRule(
                id: "rule_status_test",
                type: .statusChange,
                enabled: true,
                keyword: "",
                createdAt: Date()
            )
        )

        let added = store.addAlertIfEnabled(
            type: .statusChange,
            title: "Allowed",
            message: "Should be added"
        )
        #expect(added == true)
        #expect(store.items.count == 1)
    }

    @Test func workspaceStoreUpsertPersistsRecordsAndSnapshots() {
        let suiteName = "workspace-store-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = WorkspaceStore(defaults: defaults)
        let opportunity = makeOpportunity(id: "opp-2", title: "Workspace Opportunity")
        var record = store.record(for: opportunity)
        record.notes.append(
            WorkspaceNote(id: "note-1", title: "Plan", body: "Draft response", updatedAt: Date())
        )
        store.upsert(record)

        let reloaded = WorkspaceStore(defaults: defaults)
        let saved = reloaded.records.first!

        #expect(reloaded.records.count == 1)
        #expect(saved.opportunityID == "opp-2")
        #expect(saved.notes.count == 1)
        #expect(saved.snapshot?.solicitationNumber == opportunity.solicitationNumber)
        #expect(saved.snapshot?.contacts.count == opportunity.contacts.count)
        #expect(saved.snapshot?.resourceLinks == opportunity.resourceLinks)
    }

    @Test func workspaceStoreRefreshesSnapshotWithoutClearingUserData() {
        let suiteName = "workspace-store-refresh-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = WorkspaceStore(defaults: defaults)
        let originalOpportunity = makeOpportunity(id: "opp-refresh", title: "Original Title", agency: "Original Agency")
        var record = store.record(for: originalOpportunity)
        record.tasks.append(WorkspaceTask(id: "task-1", title: "Draft outreach", completed: false, dueDate: nil))
        record.notes.append(WorkspaceNote(id: "note-1", title: "Plan", body: "Keep this note", updatedAt: Date()))
        store.upsert(record)

        let refreshedOpportunity = makeOpportunity(id: "opp-refresh", title: "Updated Title", agency: "Updated Agency")
        let refreshedRecord = store.record(for: refreshedOpportunity)

        #expect(refreshedRecord.opportunityTitle == "Updated Title")
        #expect(refreshedRecord.snapshot?.agency == "Updated Agency")
        #expect(refreshedRecord.tasks.count == 1)
        #expect(refreshedRecord.notes.count == 1)
    }

    @Test func workspaceStoreLegacyRecordsLoadAndUpgradeSnapshots() throws {
        let suiteName = "workspace-store-legacy-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let legacyRecord = LegacyWorkspaceRecord(
            id: "workspace-legacy-1",
            opportunityID: "opp-legacy-1",
            opportunityTitle: "Legacy Workspace Opportunity",
            tasks: [WorkspaceTask(id: "task-1", title: "Keep task", completed: false, dueDate: nil)],
            notes: [WorkspaceNote(id: "note-1", title: "Keep note", body: "Still here", updatedAt: Date())],
            documents: [],
            activity: [WorkspaceActivity(id: "activity-1", text: "Created earlier", createdAt: Date())],
            updatedAt: Date(timeIntervalSince1970: 300)
        )

        let data = try JSONEncoder().encode([legacyRecord])
        defaults.set(data, forKey: "v2.workspace.records")

        let store = WorkspaceStore(defaults: defaults)
        let loaded = try #require(store.records.first)

        #expect(loaded.snapshot == nil)
        #expect(loaded.tasks.count == 1)
        #expect(loaded.notes.count == 1)

        let upgraded = store.record(for: makeOpportunity(id: "opp-legacy-1", title: "Upgraded Title", agency: "Upgraded Agency"))

        #expect(upgraded.opportunityTitle == "Upgraded Title")
        #expect(upgraded.snapshot?.agency == "Upgraded Agency")
        #expect(upgraded.tasks.count == 1)
        #expect(upgraded.notes.count == 1)
    }

    @Test func workspaceStoreRemoveDeletesPersistedRecord() {
        let suiteName = "workspace-store-remove-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = WorkspaceStore(defaults: defaults)
        let record = store.record(for: makeOpportunity(id: "opp-3", title: "Removable Workspace Opportunity"))

        #expect(store.records.count == 1)

        store.remove(recordID: record.id)

        #expect(store.records.isEmpty)

        let reloaded = WorkspaceStore(defaults: defaults)
        #expect(reloaded.records.isEmpty)
    }
}

private struct LegacyWatchlistItemRecord: Codable {
    let id: String
    var opportunityID: String
    var title: String
    var agency: String
    var postedDate: String?
    var responseDate: String?
    var status: WatchStatus
    var notes: String
    var createdAt: Date
    var updatedAt: Date
}

private struct LegacyWorkspaceRecord: Codable {
    let id: String
    var opportunityID: String
    var opportunityTitle: String
    var tasks: [WorkspaceTask]
    var notes: [WorkspaceNote]
    var documents: [WorkspaceDocument]
    var activity: [WorkspaceActivity]
    var updatedAt: Date
}

private func makeOpportunity(
    id: String,
    title: String = "Persisted Opportunity",
    agency: String = "Agency"
) -> Opportunity {
    Opportunity(
        id: id,
        title: title,
        agency: agency,
        postedDate: "03/01/2026",
        description: "Detailed description",
        solicitationNumber: "SOL-\(id)",
        fullParentPathName: "Department/Division/\(id)",
        fullParentPathCode: "CODE-\(id)",
        office: "Office \(id)",
        uiLink: "https://sam.gov/\(id)",
        additionalInfoLink: "https://example.com/\(id)",
        resourceLinks: ["https://example.com/\(id)/attachment.pdf"],
        responseDate: "03/15/2026",
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
