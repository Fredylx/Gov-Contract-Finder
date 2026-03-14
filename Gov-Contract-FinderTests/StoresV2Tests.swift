import Foundation
import Testing
@testable import Gov_Contract_Finder

@MainActor
struct StoresV2Tests {
    @Test func watchlistStorePersistsAcrossInstances() {
        let suiteName = "watchlist-store-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = WatchlistStore(defaults: defaults)
        let opportunity = Opportunity(
            id: "opp-1",
            title: "Persisted Opportunity",
            agency: "Agency",
            postedDate: "03/01/2026",
            description: "desc",
            solicitationNumber: "SOL-1",
            contacts: []
        )
        store.add(opportunity)

        let reloaded = WatchlistStore(defaults: defaults)
        #expect(reloaded.items.count == 1)
        #expect(reloaded.items.first?.opportunityID == "opp-1")
        #expect(reloaded.contains(opportunityID: "opp-1"))
    }

    @Test func watchlistStoreRemoveAllClearsPersistedItems() {
        let suiteName = "watchlist-remove-all-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = WatchlistStore(defaults: defaults)
        let opportunities = [
            Opportunity(
                id: "opp-1",
                title: "First Opportunity",
                agency: "Agency",
                postedDate: "03/01/2026",
                description: "desc",
                solicitationNumber: "SOL-1",
                contacts: []
            ),
            Opportunity(
                id: "opp-2",
                title: "Second Opportunity",
                agency: "Agency",
                postedDate: "03/02/2026",
                description: "desc",
                solicitationNumber: "SOL-2",
                contacts: []
            )
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

    @Test func workspaceStoreUpsertPersistsRecords() {
        let suiteName = "workspace-store-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = WorkspaceStore(defaults: defaults)
        var record = store.record(for: "opp-2", fallbackTitle: "Workspace Opportunity")
        record.notes.append(
            WorkspaceNote(id: "note-1", title: "Plan", body: "Draft response", updatedAt: Date())
        )
        store.upsert(record)

        let reloaded = WorkspaceStore(defaults: defaults)
        #expect(reloaded.records.count == 1)
        #expect(reloaded.records.first?.opportunityID == "opp-2")
        #expect(reloaded.records.first?.notes.count == 1)
    }
}
