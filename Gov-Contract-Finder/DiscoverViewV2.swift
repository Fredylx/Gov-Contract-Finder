import SwiftUI
import Observation

@MainActor
@Observable
final class DiscoverViewModelV2 {
    enum SortOption: String, CaseIterable, Identifiable {
        case postedNewest
        case postedOldest
        case titleAZ
        case titleZA

        var id: String { rawValue }

        var title: String {
            switch self {
            case .postedNewest: return "Posted ↓"
            case .postedOldest: return "Posted ↑"
            case .titleAZ: return "Title A-Z"
            case .titleZA: return "Title Z-A"
            }
        }

        var sort: String {
            switch self {
            case .postedNewest, .postedOldest: return "postedDate"
            case .titleAZ, .titleZA: return "title"
            }
        }

        var order: String {
            switch self {
            case .postedNewest, .titleZA: return "desc"
            case .postedOldest, .titleAZ: return "asc"
            }
        }
    }

    private let repository: OpportunityRepository
    private let pageSize = 25

    var query: String = ""
    var postedFrom: String = ""
    var postedTo: String = ""
    var naics: String = ""
    var agency: String = ""
    var noticeType: String = ""
    var setAsideCode: String = ""
    var sortOption: SortOption = .postedNewest

    var opportunities: [Opportunity] = []
    var totalRecords: Int = 0
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String?

    init(repository: OpportunityRepository) {
        self.repository = repository
        applyLastSixMonthsPreset()
    }

    var canLoadMore: Bool {
        opportunities.count < totalRecords
    }

    func applyLastSixMonthsPreset() {
        let now = Date()
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        postedFrom = Self.format(date: sixMonthsAgo)
        postedTo = Self.format(date: now)
    }

    func applySoftwarePreset() {
        query = "software"
        naics = ""
        applyLastSixMonthsPreset()
    }

    func applyNAICSPreset(_ code: String) {
        naics = code
        applyLastSixMonthsPreset()
    }

    func search() async {
        guard !postedFrom.isEmpty, !postedTo.isEmpty else {
            errorMessage = "Posted From and Posted To are required."
            return
        }

        if !Self.isValidDate(postedFrom) || !Self.isValidDate(postedTo) {
            errorMessage = "Date format must be MM/dd/yyyy."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let page = try await repository.search(filters: filters, limit: pageSize, offset: 0)
            opportunities = page.opportunities
            totalRecords = page.totalRecords
        } catch {
            errorMessage = error.localizedDescription
            opportunities = []
            totalRecords = 0
        }
    }

    func loadMoreIfNeeded(currentID: String) async {
        guard !isLoadingMore, canLoadMore else { return }
        guard opportunities.last?.id == currentID else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await repository.search(filters: filters, limit: pageSize, offset: opportunities.count)
            opportunities.append(contentsOf: page.opportunities)
            totalRecords = max(totalRecords, page.totalRecords)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var filters: OpportunitySearchFiltersV2 {
        OpportunitySearchFiltersV2(
            query: query,
            postedFrom: postedFrom,
            postedTo: postedTo,
            naics: naics.nilIfEmpty,
            agency: agency.nilIfEmpty,
            noticeType: noticeType.nilIfEmpty,
            setAsideCode: setAsideCode.nilIfEmpty,
            sort: sortOption.sort,
            order: sortOption.order
        )
    }

    private static func isValidDate(_ value: String) -> Bool {
        let pattern = #"^\d{2}/\d{2}/\d{4}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    private static func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }
}

struct DiscoverViewV2: View {
    @State private var viewModel: DiscoverViewModelV2

    @Bindable var watchlistStore: WatchlistStore
    @Bindable var alertsStore: AlertsStore
    @Bindable var workspaceStore: WorkspaceStore

    init(
        repository: OpportunityRepository = SAMOpportunityRepository(),
        watchlistStore: WatchlistStore,
        alertsStore: AlertsStore,
        workspaceStore: WorkspaceStore
    ) {
        _viewModel = State(initialValue: DiscoverViewModelV2(repository: repository))
        self.watchlistStore = watchlistStore
        self.alertsStore = alertsStore
        self.workspaceStore = workspaceStore
    }

    var body: some View {
        SafeEdgeScrollColumn {
            header
            filterSection
            statusSection
            resultsSection
        }
        .background(CyberpunkBackgroundV2())
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard viewModel.opportunities.isEmpty, !viewModel.isLoading else { return }
            await viewModel.search()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
            Text("Gov Contract Finder V2")
                .font(DesignTokensV2.Typography.hero)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            Text("Find and qualify federal opportunities faster.")
                .font(DesignTokensV2.Typography.body)
                .foregroundStyle(DesignTokensV2.Colors.textSecondary)
        }
    }

    private var filterSection: some View {
        NeoCard {
            InputFieldV2(title: "Keyword", placeholder: "software, AI, cloud...", text: $viewModel.query)
            InputFieldV2(title: "Posted From", placeholder: "MM/dd/yyyy", text: $viewModel.postedFrom)
            InputFieldV2(title: "Posted To", placeholder: "MM/dd/yyyy", text: $viewModel.postedTo)
            InputFieldV2(title: "NAICS", placeholder: "541519", text: $viewModel.naics, keyboardType: .numbersAndPunctuation)
            InputFieldV2(title: "Agency", placeholder: "Department", text: $viewModel.agency)

            HStack {
                Menu {
                    ForEach(DiscoverViewModelV2.SortOption.allCases) { option in
                        Button(option.title) {
                            viewModel.sortOption = option
                        }
                    }
                } label: {
                    BadgeV2(text: viewModel.sortOption.title, color: DesignTokensV2.Colors.accentViolet)
                }
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokensV2.Spacing.xs) {
                    FilterChipV2(title: "Software Preset", selected: false) {
                        viewModel.applySoftwarePreset()
                    }
                    FilterChipV2(title: "NAICS 541519", selected: false) {
                        viewModel.applyNAICSPreset("541519")
                    }
                    FilterChipV2(title: "NAICS 541511", selected: false) {
                        viewModel.applyNAICSPreset("541511")
                    }
                }
            }

            NeonButton(title: "Search", icon: "magnifyingglass", enabled: !viewModel.isLoading) {
                Task { await viewModel.search() }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if let error = viewModel.errorMessage {
            NeoCard {
                Text("Error")
                    .font(DesignTokensV2.Typography.section)
                    .foregroundStyle(DesignTokensV2.Colors.danger)
                BoundedBodyText(value: error, color: DesignTokensV2.Colors.textPrimary)
            }
        } else if viewModel.isLoading {
            NeoCard {
                ProgressView("Loading opportunities...")
                    .tint(DesignTokensV2.Colors.accentCyan)
                    .foregroundStyle(DesignTokensV2.Colors.textSecondary)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if !viewModel.opportunities.isEmpty {
            HStack {
                BoundedBodyText(
                    value: "Showing \(viewModel.opportunities.count) of \(viewModel.totalRecords)",
                    font: DesignTokensV2.Typography.caption
                )
                Spacer()
            }

            LazyVStack(spacing: DesignTokensV2.Spacing.s) {
                ForEach(viewModel.opportunities) { opportunity in
                    NavigationLink {
                        OpportunityDetailView(
                            opportunity: opportunity,
                            watchlistStore: watchlistStore,
                            alertsStore: alertsStore,
                            workspaceStore: workspaceStore
                        )
                    } label: {
                        OpportunityCardV2(
                            opportunity: opportunity,
                            isSaved: watchlistStore.contains(opportunityID: opportunity.id),
                            onSave: {
                                watchlistStore.add(opportunity)
                                alertsStore.addAlert(
                                    type: .statusChange,
                                    title: "Added to Watchlist",
                                    message: opportunity.title,
                                    opportunityID: opportunity.id
                                )
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.loadMoreIfNeeded(currentID: opportunity.id)
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(DesignTokensV2.Colors.accentCyan)
                        .padding(.top, DesignTokensV2.Spacing.s)
                }
            }
        } else if !viewModel.isLoading {
            NeoCard {
                Text("No opportunities yet")
                    .font(DesignTokensV2.Typography.section)
                    .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                BoundedBodyText(value: "Run a search to load opportunities from SAM.gov.")
            }
        }
    }
}

private struct OpportunityCardV2: View {
    let opportunity: Opportunity
    let isSaved: Bool
    let onSave: () -> Void

    var body: some View {
        NeoCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
                    BoundedBodyText(
                        value: opportunity.title,
                        font: DesignTokensV2.Typography.section,
                        color: DesignTokensV2.Colors.textPrimary
                    )

                    if let agency = opportunity.agency {
                        BoundedBodyText(value: agency)
                    }

                    HStack(spacing: DesignTokensV2.Spacing.xs) {
                        if let posted = opportunity.postedDate {
                            BadgeV2(text: "Posted \(posted)", color: DesignTokensV2.Colors.accentCyan)
                        }
                        if let due = opportunity.responseDate {
                            BadgeV2(text: "Due \(due)", color: DesignTokensV2.Colors.warning)
                        }
                    }
                }

                Spacer(minLength: DesignTokensV2.Spacing.s)

                Button {
                    onSave()
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(isSaved ? DesignTokensV2.Colors.accentLime : DesignTokensV2.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
