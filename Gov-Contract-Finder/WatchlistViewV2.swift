import SwiftUI

struct WatchlistViewV2: View {
    @Bindable var watchlistStore: WatchlistStore
    @Bindable var alertsStore: AlertsStore
    @Bindable var workspaceStore: WorkspaceStore

    @State private var selectedStatus: WatchStatus? = nil
    @State private var dueSoonOnly = false
    @State private var highMatchOnly = false
    @State private var assignedToMeOnly = false

    var body: some View {
        SafeEdgeScrollColumn(maxContentWidth: 980) {
            header
            quickFilters

            if watchlistStore.items.isEmpty {
                NeoCard {
                    Text("No watchlist items")
                        .font(DesignTokensV2.Typography.section)
                        .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                    BoundedBodyText(value: "Save opportunities from Discover to start your pipeline.")
                }
            } else {
                pipelineBoard
            }
        }
        .background(CyberpunkBackgroundV2())
        .navigationTitle("Watchlist")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: DesignTokensV2.Spacing.m) {
                headerCopy
                Spacer(minLength: DesignTokensV2.Spacing.s)
                bulkActions
            }

            VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.s) {
                headerCopy
                HStack {
                    Spacer()
                    bulkActions
                }
            }
        }
    }

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
            Text("Pipeline")
                .font(DesignTokensV2.Typography.hero)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)
            Text("Drag opportunities between stages")
                .font(DesignTokensV2.Typography.body)
                .foregroundStyle(DesignTokensV2.Colors.textSecondary)
        }
    }

    @ViewBuilder
    private var bulkActions: some View {
        if !watchlistStore.items.isEmpty {
            ActionPillV2(
                title: "Remove All",
                tint: DesignTokensV2.Colors.danger,
                icon: "trash",
                confirmation: ActionConfirmationV2(
                    title: "Remove all bookmarks?",
                    message: "This removes all saved opportunities from your watchlist. Workspace records and alerts stay untouched.",
                    confirmLabel: "Remove All",
                    role: .destructive
                )
            ) {
                watchlistStore.removeAll()
            }
        }
    }

    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokensV2.Spacing.xs) {
                FilterChipV2(title: "All", selected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                FilterChipV2(title: "Due Soon", selected: dueSoonOnly) {
                    dueSoonOnly.toggle()
                }
                FilterChipV2(title: "High Match", selected: highMatchOnly) {
                    highMatchOnly.toggle()
                }
                FilterChipV2(title: "Assigned to Me", selected: assignedToMeOnly) {
                    assignedToMeOnly.toggle()
                }
            }
        }
    }

    private var pipelineBoard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: DesignTokensV2.Spacing.m) {
                ForEach(visibleStatuses, id: \.self) { status in
                    statusColumn(status)
                }
            }
            .padding(.bottom, DesignTokensV2.Spacing.xs)
        }
    }

    private func statusColumn(_ status: WatchStatus) -> some View {
        let items = filteredItems(for: status)

        return VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.s) {
            HStack(spacing: DesignTokensV2.Spacing.xs) {
                Circle()
                    .fill(color(for: status))
                    .frame(width: 8, height: 8)

                Text(status.title)
                    .font(DesignTokensV2.Typography.bodyStrong)
                    .foregroundStyle(DesignTokensV2.Colors.textPrimary)

                Spacer()

                Text("\(items.count)")
                    .font(DesignTokensV2.Typography.caption)
                    .foregroundStyle(DesignTokensV2.Colors.textSecondary)
            }

            if items.isEmpty {
                BoundedBodyText(value: "No opportunities in this stage.")
            } else {
                ForEach(items) { item in
                    NavigationLink {
                        OpportunityDetailView(
                            opportunity: item.asOpportunity,
                            watchlistStore: watchlistStore,
                            alertsStore: alertsStore,
                            workspaceStore: workspaceStore
                        )
                    } label: {
                        pipelineCard(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DesignTokensV2.Spacing.m)
        .frame(width: 304, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.card, style: .continuous)
                .fill(DesignTokensV2.Colors.surface.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.card, style: .continuous)
                .stroke(DesignTokensV2.Colors.border, lineWidth: 1)
        )
    }

    private func pipelineCard(_ item: WatchlistItem) -> some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
            Text(OpportunityDetailTextFormatter.wrapUnsafeTokens(item.title))
                .font(DesignTokensV2.Typography.bodyStrong)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: DesignTokensV2.Spacing.xs) {
                Image(systemName: "building.2")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignTokensV2.Colors.textSecondary)

                Text(OpportunityDetailTextFormatter.wrapUnsafeTokens(item.agency))
                    .font(DesignTokensV2.Typography.caption)
                    .foregroundStyle(DesignTokensV2.Colors.textSecondary)
                    .lineLimit(1)
            }

            HStack(spacing: DesignTokensV2.Spacing.xs) {
                BadgeV2(text: "\(matchPercent(for: item))% Match", color: DesignTokensV2.Colors.accentCyan)
                if let due = dueLabel(for: item) {
                    BadgeV2(text: due, color: DesignTokensV2.Colors.warning)
                }
            }

            HStack(spacing: DesignTokensV2.Spacing.s) {
                Menu {
                    ForEach(WatchStatus.allCases) { status in
                        Button(status.title) {
                            watchlistStore.setStatus(opportunityID: item.opportunityID, status: status)
                            alertsStore.addAlertIfEnabled(
                                type: .statusChange,
                                title: "Watchlist Status Updated",
                                message: "\(item.title) -> \(status.title)",
                                opportunityID: item.opportunityID,
                                snapshot: item.resolvedSnapshot
                            )
                        }
                    }
                } label: {
                    Text(item.status.title)
                        .font(DesignTokensV2.Typography.caption)
                        .foregroundStyle(color(for: item.status))
                }

                Spacer()

                Button("Dismiss") {
                    watchlistStore.remove(opportunityID: item.opportunityID)
                }
                .font(DesignTokensV2.Typography.caption)
                .foregroundStyle(DesignTokensV2.Colors.danger)
            }
        }
        .padding(DesignTokensV2.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                .fill(DesignTokensV2.Colors.surface2.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                .stroke(DesignTokensV2.Colors.border.opacity(0.7), lineWidth: 1)
        )
    }

    private var visibleStatuses: [WatchStatus] {
        if let selectedStatus {
            return [selectedStatus]
        }
        return [.new, .reviewing, .pursuing]
    }

    private func filteredItems(for status: WatchStatus) -> [WatchlistItem] {
        watchlistStore.items
            .filter { $0.status == status }
            .filter { !dueSoonOnly || isDueSoon($0) }
            .filter { !highMatchOnly || matchPercent(for: $0) >= 88 }
            .filter { !assignedToMeOnly || isAssignedToMe($0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func isAssignedToMe(_ item: WatchlistItem) -> Bool {
        abs(item.opportunityID.hashValue % 2) == 0
    }

    private func matchPercent(for item: WatchlistItem) -> Int {
        let base = abs(item.opportunityID.hashValue % 16)
        return 80 + base
    }

    private func isDueSoon(_ item: WatchlistItem) -> Bool {
        guard let days = daysUntilResponse(for: item), days >= 0 else { return false }
        return days <= 14
    }

    private func dueLabel(for item: WatchlistItem) -> String? {
        guard let days = daysUntilResponse(for: item) else { return nil }
        if days < 0 {
            return "Expired"
        }
        return "\(days)d left"
    }

    private func daysUntilResponse(for item: WatchlistItem) -> Int? {
        guard let responseDate = item.responseDate else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd/yyyy"
        guard let date = formatter.date(from: responseDate) else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day
        return days
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
