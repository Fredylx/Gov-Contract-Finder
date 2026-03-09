import SwiftUI
import Observation
import OSLog

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
            case .postedNewest: return "Posted Date (Newest)"
            case .postedOldest: return "Posted Date (Oldest)"
            case .titleAZ: return "Title (A-Z)"
            case .titleZA: return "Title (Z-A)"
            }
        }

        var sort: String {
            switch self {
            case .postedNewest, .postedOldest:
                return "postedDate"
            case .titleAZ, .titleZA:
                return "title"
            }
        }

        var order: String {
            switch self {
            case .postedNewest, .titleZA:
                return "desc"
            case .postedOldest, .titleAZ:
                return "asc"
            }
        }
    }

    struct ActiveFilter: Identifiable {
        enum Key: String, Hashable {
            case query
            case agency
            case naics
            case postedFrom
            case postedTo
            case noticeType
            case setAsideCode
        }

        let key: Key
        let label: String
        let value: String

        var id: String { key.rawValue }
    }

    private let repository: OpportunityRepository
    private let pageSize = 25
    private let searchCooldown: TimeInterval = 0.8
    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "DiscoverViewModelV2")

    private var lastSearchTapAt: Date = .distantPast

    var query: String = ""
    var postedFrom: String = ""
    var postedTo: String = ""
    var naics: String = ""
    var agency: String = ""
    var noticeType: String = ""
    var setAsideCode: String = ""
    var sortOption: SortOption = .postedNewest

    var showAdvancedFilters = false

    var opportunities: [Opportunity] = []
    var totalRecords: Int = 0
    var isLoading = false
    var isLoadingMore = false
    var hasSearched = false
    var errorMessage: String?

    init(repository: OpportunityRepository) {
        self.repository = repository
        applyLastSixMonthsPreset()
    }

    var canLoadMore: Bool {
        opportunities.count < totalRecords
    }

    var canSubmitSearch: Bool {
        !isLoading && !isLoadingMore && Date().timeIntervalSince(lastSearchTapAt) >= searchCooldown
    }

    var hasValidSearchInputs: Bool {
        validateSearchInputs() == nil
    }

    var activeFilters: [ActiveFilter] {
        var filters: [ActiveFilter] = []

        if let value = query.nilIfEmpty {
            filters.append(.init(key: .query, label: "Keyword", value: value))
        }
        if let value = agency.nilIfEmpty {
            filters.append(.init(key: .agency, label: "Agency", value: value))
        }
        if let value = naics.nilIfEmpty {
            filters.append(.init(key: .naics, label: "NAICS", value: value))
        }
        if let value = postedFrom.nilIfEmpty {
            filters.append(.init(key: .postedFrom, label: "From", value: value))
        }
        if let value = postedTo.nilIfEmpty {
            filters.append(.init(key: .postedTo, label: "To", value: value))
        }
        if let value = noticeType.nilIfEmpty {
            filters.append(.init(key: .noticeType, label: "Notice", value: value))
        }
        if let value = setAsideCode.nilIfEmpty {
            filters.append(.init(key: .setAsideCode, label: "Set-Aside", value: value))
        }

        return filters
    }

    func applyLastSixMonthsPreset() {
        let now = Date()
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        postedFrom = Self.format(date: sixMonthsAgo)
        postedTo = Self.format(date: now)
    }

    func applySoftwarePreset() {
        query = "software"
        setAsideCode = ""
        applyLastSixMonthsPreset()
    }

    func applySmallCompanyPreset() {
        query = "services"
        setAsideCode = "SBA"
        applyLastSixMonthsPreset()
    }

    func applySoftwareSmallCompanyPreset() {
        query = "software"
        setAsideCode = "SBA"
        applyLastSixMonthsPreset()
    }

    func clearFilter(_ key: ActiveFilter.Key) {
        switch key {
        case .query: query = ""
        case .agency: agency = ""
        case .naics: naics = ""
        case .postedFrom: postedFrom = ""
        case .postedTo: postedTo = ""
        case .noticeType: noticeType = ""
        case .setAsideCode: setAsideCode = ""
        }
    }

    func search() async {
        guard canSubmitSearch else { return }
        hasSearched = true
        lastSearchTapAt = Date()
        let start = Date()
        debugLog("search start query=\"\(query.trimmedForDebug)\" offset=0 limit=\(pageSize) filters=\(debugFilterSummary)")

        if let validationError = validateSearchInputs() {
            errorMessage = validationError
            opportunities = []
            totalRecords = 0
            debugLog("search validation failed message=\"\(validationError.trimmedForDebug)\"")
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let page = try await repository.search(filters: filters, limit: pageSize, offset: 0)
            opportunities = page.opportunities
            totalRecords = page.totalRecords
            let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
            debugLog("search success count=\(page.opportunities.count) total=\(page.totalRecords) elapsedMs=\(elapsedMs)")
        } catch {
            errorMessage = error.localizedDescription
            opportunities = []
            totalRecords = 0
            let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
            debugLog("search failed error=\"\(error.localizedDescription.trimmedForDebug)\" elapsedMs=\(elapsedMs)")
        }
    }

    func loadMoreIfNeeded(currentID: String) async {
        guard hasSearched, !isLoading, !isLoadingMore, canLoadMore else { return }
        guard opportunities.last?.id == currentID else { return }

        isLoadingMore = true
        let offset = opportunities.count
        let start = Date()
        debugLog("loadMore start offset=\(offset) limit=\(pageSize)")
        defer { isLoadingMore = false }

        do {
            let page = try await repository.search(filters: filters, limit: pageSize, offset: offset)
            opportunities.append(contentsOf: page.opportunities)
            totalRecords = max(totalRecords, page.totalRecords)
            let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
            debugLog("loadMore success appended=\(page.opportunities.count) totalNow=\(opportunities.count) elapsedMs=\(elapsedMs)")
        } catch {
            errorMessage = error.localizedDescription
            let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
            debugLog("loadMore failed error=\"\(error.localizedDescription.trimmedForDebug)\" elapsedMs=\(elapsedMs)")
        }
    }

    private var filters: OpportunitySearchFiltersV2 {
        OpportunitySearchFiltersV2(
            query: query.trimmingCharacters(in: .whitespacesAndNewlines),
            postedFrom: postedFrom.nilIfEmpty,
            postedTo: postedTo.nilIfEmpty,
            naics: naics.nilIfEmpty,
            agency: agency.nilIfEmpty,
            noticeType: noticeType.nilIfEmpty,
            setAsideCode: setAsideCode.nilIfEmpty,
            sort: sortOption.sort,
            order: sortOption.order
        )
    }

    private func validateSearchInputs() -> String? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            return "Search text cannot be empty."
        }

        let hasFrom = !postedFrom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasTo = !postedTo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if hasFrom != hasTo {
            return "Posted From and Posted To must both be provided."
        }

        if hasFrom && !Self.isValidDate(postedFrom) {
            return "Posted From must use MM/dd/yyyy."
        }

        if hasTo && !Self.isValidDate(postedTo) {
            return "Posted To must use MM/dd/yyyy."
        }

        return nil
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

    private var debugFilterSummary: String {
        var pairs: [String] = []
        if let agency = agency.nilIfEmpty { pairs.append("agency=\(agency.trimmedForDebug)") }
        if let naics = naics.nilIfEmpty { pairs.append("naics=\(naics.trimmedForDebug)") }
        if let from = postedFrom.nilIfEmpty { pairs.append("from=\(from)") }
        if let to = postedTo.nilIfEmpty { pairs.append("to=\(to)") }
        if let noticeType = noticeType.nilIfEmpty { pairs.append("notice=\(noticeType.trimmedForDebug)") }
        if let setAsideCode = setAsideCode.nilIfEmpty { pairs.append("setAside=\(setAsideCode.trimmedForDebug)") }
        pairs.append("sort=\(sortOption.sort)-\(sortOption.order)")
        return pairs.joined(separator: ",")
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        guard DebugSettings.shared.isEnabled else { return }
        logger.debug("\(message, privacy: .public)")
        #endif
    }
}

struct DiscoverViewV2: View {
    private static let viewedIDsStorageKey = "v2.discover.viewedOpportunityIDs"

    @State private var viewModel: DiscoverViewModelV2
    @State private var viewedOpportunityIDs: Set<String>

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
        _viewedOpportunityIDs = State(initialValue: Set(UserDefaults.standard.stringArray(forKey: Self.viewedIDsStorageKey) ?? []))
        self.watchlistStore = watchlistStore
        self.alertsStore = alertsStore
        self.workspaceStore = workspaceStore
    }

    var body: some View {
        SafeEdgeScrollColumn {
            header
            searchControlsCard
            activeFilterSection
            resultsSection
        }
        .background(CyberpunkBackgroundV2())
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
            Text("Discover")
                .font(DesignTokensV2.Typography.hero)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            Text("Find federal opportunities for your team.")
                .font(DesignTokensV2.Typography.body)
                .foregroundStyle(DesignTokensV2.Colors.textSecondary)
        }
    }

    private var searchControlsCard: some View {
        NeoCard {
            VStack(spacing: DesignTokensV2.Spacing.s) {
                HStack(spacing: DesignTokensV2.Spacing.s) {
                    DiscoverPresetButton(
                        title: "Software",
                        icon: "laptopcomputer",
                        startColor: DesignTokensV2.Colors.accentCyan,
                        endColor: DesignTokensV2.Colors.accentViolet,
                        selected: isSoftwarePresetSelected
                    ) {
                        viewModel.applySoftwarePreset()
                        SearchAdsCoordinator.shared.triggerAfterUserAction("discover_preset_software")
                    }

                    DiscoverPresetButton(
                        title: "Small Cos",
                        icon: "building.2",
                        startColor: DesignTokensV2.Colors.accentMagenta,
                        endColor: DesignTokensV2.Colors.accentLime,
                        selected: isSmallCosPresetSelected
                    ) {
                        viewModel.applySmallCompanyPreset()
                        SearchAdsCoordinator.shared.triggerAfterUserAction("discover_preset_small_cos")
                    }
                }

                DiscoverPresetButton(
                    title: "Software + Small Business",
                    icon: "bolt.fill",
                    startColor: DesignTokensV2.Colors.accentViolet,
                    endColor: DesignTokensV2.Colors.accentCyan,
                    selected: isSoftwareSmallPresetSelected
                ) {
                    viewModel.applySoftwareSmallCompanyPreset()
                    SearchAdsCoordinator.shared.triggerAfterUserAction("discover_preset_software_small")
                }

                HStack(spacing: DesignTokensV2.Spacing.s) {
                    TextField("Search keywords...", text: $viewModel.query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(DesignTokensV2.Typography.body)
                        .foregroundStyle(DesignTokensV2.Colors.textPrimary)

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignTokensV2.Colors.accentCyan)
                }
                .padding(.horizontal, DesignTokensV2.Spacing.m)
                .padding(.vertical, DesignTokensV2.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                        .fill(DesignTokensV2.Colors.bg800.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                        .stroke(DesignTokensV2.Colors.border, lineWidth: 1)
                )
            }

            Button {
                Task { await runSearchFromCTA() }
            } label: {
                HStack(spacing: DesignTokensV2.Spacing.xs) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(DesignTokensV2.Colors.bg900)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(viewModel.isLoading ? "Searching..." : "Search Opportunities")
                }
                .font(DesignTokensV2.Typography.bodyStrong)
                .foregroundStyle(DesignTokensV2.Colors.bg900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokensV2.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                        .fill(
                            viewModel.canSubmitSearch
                            ? LinearGradient(
                                colors: [DesignTokensV2.Colors.accentCyan, DesignTokensV2.Colors.accentViolet],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [DesignTokensV2.Colors.textSecondary.opacity(0.35), DesignTokensV2.Colors.textSecondary.opacity(0.35)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(
                    color: viewModel.canSubmitSearch ? DesignTokensV2.Colors.accentCyan.opacity(0.25) : .clear,
                    radius: 14
                )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSubmitSearch)

            Button {
                withAnimation(DesignTokensV2.Animation.quick) {
                    viewModel.showAdvancedFilters.toggle()
                }
                SearchAdsCoordinator.shared.triggerAfterUserAction("discover_toggle_filters")
            } label: {
                HStack(spacing: DesignTokensV2.Spacing.xs) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Filters")
                    Image(systemName: viewModel.showAdvancedFilters ? "chevron.up" : "chevron.down")
                    Spacer()
                }
                .font(DesignTokensV2.Typography.bodyStrong)
                .foregroundStyle(DesignTokensV2.Colors.accentCyan)
            }
            .buttonStyle(.plain)

            if viewModel.showAdvancedFilters {
                VStack(spacing: DesignTokensV2.Spacing.s) {
                    InputFieldV2(title: "Agency", placeholder: "Department of Defense", text: $viewModel.agency)
                    InputFieldV2(title: "NAICS Code", placeholder: "541519", text: $viewModel.naics, keyboardType: .numbersAndPunctuation)

                    HStack(spacing: DesignTokensV2.Spacing.s) {
                        InputFieldV2(title: "Posted From", placeholder: "MM/dd/yyyy", text: $viewModel.postedFrom)
                        InputFieldV2(title: "Posted To", placeholder: "MM/dd/yyyy", text: $viewModel.postedTo)
                    }

                    InputFieldV2(title: "Notice Type", placeholder: "Solicitation", text: $viewModel.noticeType)
                    InputFieldV2(title: "Set-Aside", placeholder: "SBA", text: $viewModel.setAsideCode)

                    HStack {
                        Menu {
                            ForEach(DiscoverViewModelV2.SortOption.allCases) { option in
                                Button(option.title) {
                                    viewModel.sortOption = option
                                    SearchAdsCoordinator.shared.triggerAfterUserAction("discover_sort_\(option.rawValue)")
                                }
                            }
                        } label: {
                            BadgeV2(text: viewModel.sortOption.title, color: DesignTokensV2.Colors.accentViolet)
                        }
                        Spacer()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var isSoftwarePresetSelected: Bool {
        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "software"
        && viewModel.setAsideCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isSmallCosPresetSelected: Bool {
        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "services"
        && viewModel.setAsideCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "SBA"
    }

    private var isSoftwareSmallPresetSelected: Bool {
        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "software"
        && viewModel.setAsideCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "SBA"
    }

    @ViewBuilder
    private var activeFilterSection: some View {
        if !viewModel.activeFilters.isEmpty {
            NeoCard {
                HStack {
                    Text("Active Filters")
                        .font(DesignTokensV2.Typography.caption)
                        .foregroundStyle(DesignTokensV2.Colors.textSecondary)
                    Spacer()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokensV2.Spacing.xs) {
                        ForEach(viewModel.activeFilters) { filter in
                            RemovableFilterChipV2(
                                label: filter.label,
                                value: filter.value
                            ) {
                                viewModel.clearFilter(filter.key)
                                SearchAdsCoordinator.shared.triggerAfterUserAction("discover_clear_filter")
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if viewModel.hasSearched, let error = viewModel.errorMessage {
            NeoCard {
                Text("Search Error")
                    .font(DesignTokensV2.Typography.section)
                    .foregroundStyle(DesignTokensV2.Colors.danger)
                BoundedBodyText(value: error, color: DesignTokensV2.Colors.textPrimary)
            }
        } else if viewModel.isLoading {
            NeoCard {
                ProgressView("Fetching opportunities...")
                    .tint(DesignTokensV2.Colors.accentCyan)
                    .foregroundStyle(DesignTokensV2.Colors.textSecondary)
            }
        } else if !viewModel.hasSearched {
            NeoCard {
                VStack(alignment: .center, spacing: DesignTokensV2.Spacing.s) {
                    ZStack {
                        Circle()
                            .fill(DesignTokensV2.Colors.surface2)
                            .frame(width: 56, height: 56)
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(DesignTokensV2.Colors.textSecondary)
                    }

                    Text("Ready to Search")
                        .font(DesignTokensV2.Typography.section)
                        .foregroundStyle(DesignTokensV2.Colors.textPrimary)

                    Text(OpportunityDetailTextFormatter.wrapUnsafeTokens("Use quick presets above or search with custom filters to discover federal opportunities."))
                        .font(DesignTokensV2.Typography.body)
                        .foregroundStyle(DesignTokensV2.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokensV2.Spacing.m)
            }
        } else if viewModel.opportunities.isEmpty {
            NeoCard {
                Text("No opportunities found")
                    .font(DesignTokensV2.Typography.section)
                    .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                BoundedBodyText(value: "Try broadening your keywords or adjusting your filters.")
            }
        } else {
            HStack {
                BoundedBodyText(
                    value: "\(viewModel.opportunities.count) opportunities shown",
                    font: DesignTokensV2.Typography.caption
                )
                Spacer()
            }

            LazyVStack(spacing: DesignTokensV2.Spacing.s) {
                ForEach(viewModel.opportunities) { opportunity in
                    ZStack(alignment: .topTrailing) {
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
                                isViewed: viewedOpportunityIDs.contains(opportunity.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            markViewed(opportunity.id)
                        })
                        .task {
                            await viewModel.loadMoreIfNeeded(currentID: opportunity.id)
                        }

                        Button {
                            toggleSaved(opportunity)
                        } label: {
                            Image(systemName: watchlistStore.contains(opportunityID: opportunity.id) ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(
                                    watchlistStore.contains(opportunityID: opportunity.id)
                                    ? DesignTokensV2.Colors.accentLime
                                    : DesignTokensV2.Colors.textSecondary
                                )
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(DesignTokensV2.Colors.surface2.opacity(0.8))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(DesignTokensV2.Spacing.s)
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(DesignTokensV2.Colors.accentCyan)
                        .padding(.top, DesignTokensV2.Spacing.s)
                }
            }
        }
    }

    private func toggleSaved(_ opportunity: Opportunity) {
        let isNowSaved = watchlistStore.toggle(opportunity)
        alertsStore.addAlert(
            type: .statusChange,
            title: isNowSaved ? "Added to Watchlist" : "Removed from Watchlist",
            message: opportunity.title,
            opportunityID: opportunity.id
        )
        SearchAdsCoordinator.shared.triggerAfterUserAction("discover_toggle_saved")
    }

    private func runSearchFromCTA() async {
        guard viewModel.canSubmitSearch else { return }

        _ = await SearchAdsCoordinator.shared.showSearchInterstitialForSearchTap()

        await viewModel.search()
        SearchAdsCoordinator.shared.preloadSearchInterstitial()
    }

    private func markViewed(_ id: String) {
        guard !viewedOpportunityIDs.contains(id) else { return }
        viewedOpportunityIDs.insert(id)
        UserDefaults.standard.set(Array(viewedOpportunityIDs), forKey: Self.viewedIDsStorageKey)
    }
}

private struct DiscoverPresetButton: View {
    let title: String
    let icon: String
    let startColor: Color
    let endColor: Color
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokensV2.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(DesignTokensV2.Typography.bodyStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(DesignTokensV2.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DesignTokensV2.Spacing.s)
            .padding(.vertical, DesignTokensV2.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                startColor.opacity(selected ? 0.5 : 0.3),
                                endColor.opacity(selected ? 0.5 : 0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                    .stroke((selected ? endColor : DesignTokensV2.Colors.border).opacity(0.85), lineWidth: 1)
            )
            .shadow(
                color: selected ? endColor.opacity(0.25) : .clear,
                radius: 10
            )
        }
        .buttonStyle(.plain)
    }
}

private struct OpportunityCardV2: View {
    let opportunity: Opportunity
    let isViewed: Bool

    var body: some View {
        NeoCard {
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
                if isViewed {
                    BadgeV2(text: "Viewed", color: DesignTokensV2.Colors.textSecondary)
                }
            }
        }
    }
}

private struct RemovableFilterChipV2: View {
    let label: String
    let value: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: DesignTokensV2.Spacing.xs) {
            Text("\(label): \(value)")
                .font(DesignTokensV2.Typography.caption)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DesignTokensV2.Colors.textPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokensV2.Spacing.s)
        .padding(.vertical, DesignTokensV2.Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(DesignTokensV2.Colors.surface2)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(DesignTokensV2.Colors.border, lineWidth: 1)
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedForDebug: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 80 { return trimmed }
        return String(trimmed.prefix(80)) + "…"
    }
}
