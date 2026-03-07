import SwiftUI

struct WatchlistViewV2: View {
    @Bindable var watchlistStore: WatchlistStore
    @Bindable var alertsStore: AlertsStore
    @Bindable var workspaceStore: WorkspaceStore

    @State private var selectedStatus: WatchStatus? = nil
    @State private var sortByNewest = true

    var body: some View {
        SafeEdgeScrollColumn {
            header
            controls

            if filteredItems.isEmpty {
                NeoCard {
                    Text("No watchlist items")
                        .font(DesignTokensV2.Typography.section)
                        .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                    BoundedBodyText(value: "Save opportunities from Discover or Detail to track them here.")
                }
            } else {
                ForEach(filteredItems) { item in
                    NavigationLink {
                        OpportunityDetailView(
                            opportunity: item.asOpportunity,
                            watchlistStore: watchlistStore,
                            alertsStore: alertsStore,
                            workspaceStore: workspaceStore
                        )
                    } label: {
                        watchlistCard(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(CyberpunkBackgroundV2())
        .navigationTitle("Watchlist")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        NeoCard {
            Text("Opportunity Watchlist")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)
            BoundedBodyText(value: "Track pursuit status and keep notes synced locally.")
        }
    }

    private var controls: some View {
        NeoCard {
            HStack {
                Menu {
                    Button("All") { selectedStatus = nil }
                    ForEach(WatchStatus.allCases) { status in
                        Button(status.title) { selectedStatus = status }
                    }
                } label: {
                    BadgeV2(
                        text: selectedStatus?.title ?? "All Statuses",
                        color: DesignTokensV2.Colors.accentViolet
                    )
                }

                Spacer()

                FilterChipV2(title: sortByNewest ? "Newest" : "Oldest", selected: true) {
                    sortByNewest.toggle()
                }
            }
        }
    }

    private func watchlistCard(_ item: WatchlistItem) -> some View {
        NeoCard {
            BoundedBodyText(
                value: item.title,
                font: DesignTokensV2.Typography.section,
                color: DesignTokensV2.Colors.textPrimary
            )

            BoundedBodyText(value: item.agency)

            HStack(spacing: DesignTokensV2.Spacing.xs) {
                BadgeV2(text: item.status.title, color: color(for: item.status))
                if let due = item.responseDate {
                    BadgeV2(text: "Due \(due)", color: DesignTokensV2.Colors.warning)
                }
            }

            HStack(spacing: DesignTokensV2.Spacing.xs) {
                Menu {
                    ForEach(WatchStatus.allCases) { status in
                        Button(status.title) {
                            watchlistStore.setStatus(opportunityID: item.opportunityID, status: status)
                            alertsStore.addAlert(
                                type: .statusChange,
                                title: "Watchlist Status Updated",
                                message: "\(item.title) -> \(status.title)",
                                opportunityID: item.opportunityID
                            )
                        }
                    }
                } label: {
                    Text("Update Status")
                        .font(DesignTokensV2.Typography.caption)
                        .foregroundStyle(DesignTokensV2.Colors.accentCyan)
                }

                Spacer()

                Button("Remove") {
                    watchlistStore.remove(opportunityID: item.opportunityID)
                }
                .font(DesignTokensV2.Typography.caption)
                .foregroundStyle(DesignTokensV2.Colors.danger)
            }

            if !item.notes.isEmpty {
                BoundedBodyText(value: "Notes: \(item.notes)")
            }
        }
    }

    private var filteredItems: [WatchlistItem] {
        let statusFiltered = watchlistStore.items.filter { item in
            guard let selectedStatus else { return true }
            return item.status == selectedStatus
        }

        return statusFiltered.sorted { lhs, rhs in
            sortByNewest ? lhs.updatedAt > rhs.updatedAt : lhs.updatedAt < rhs.updatedAt
        }
    }

    private func color(for status: WatchStatus) -> Color {
        switch status {
        case .new: return DesignTokensV2.Colors.accentCyan
        case .reviewing: return DesignTokensV2.Colors.accentViolet
        case .pursuing: return DesignTokensV2.Colors.warning
        case .submitted: return DesignTokensV2.Colors.success
        case .archived: return DesignTokensV2.Colors.textSecondary
        }
    }
}

private extension WatchlistItem {
    var asOpportunity: Opportunity {
        Opportunity(
            id: opportunityID,
            title: title,
            agency: agency,
            postedDate: postedDate,
            description: notes,
            solicitationNumber: nil,
            fullParentPathName: nil,
            fullParentPathCode: nil,
            office: nil,
            uiLink: nil,
            additionalInfoLink: nil,
            resourceLinks: [],
            responseDate: responseDate,
            setAsideCode: nil,
            naicsCode: nil,
            naicsDescription: nil,
            contacts: []
        )
    }
}
