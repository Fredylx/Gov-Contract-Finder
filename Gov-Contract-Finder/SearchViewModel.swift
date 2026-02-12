//
//  SearchViewModel.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import Foundation
import Observation
import OSLog

@Observable
final class SearchViewModel {
    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "SearchViewModel")
    private var debounceTask: Task<Void, Never>? = nil

    var searchText: String = ""
    var postedFrom: String? = nil
    var postedTo: String? = nil
    var naics: String? = nil
    var agency: String? = nil
    var noticeType: String? = nil
    var setAsideCode: String? = nil
    enum SortOption: String, CaseIterable, Identifiable {
        case postedNewest = "postedNewest"
        case postedOldest = "postedOldest"
        case titleAZ = "titleAZ"
        case titleZA = "titleZA"

        var id: String { rawValue }

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
            case .postedNewest:
                return "desc"
            case .postedOldest:
                return "asc"
            case .titleAZ:
                return "asc"
            case .titleZA:
                return "desc"
            }
        }
    }

    var sortOption: SortOption = .postedNewest
    var opportunities: [Opportunity] = []
    var totalRecords: Int = 0
    var offset: Int = 0
    let pageSize: Int = 25
    var isLoading = false
    var isLoadingMore = false
    private var lastLoadMoreAt: Date? = nil
    var error: String?

    var hasResults: Bool {
        !opportunities.isEmpty
    }

    var canLoadMore: Bool {
        totalRecords > opportunities.count
    }

    private func isValidDate(_ value: String?) -> Bool {
        guard let value, !value.isEmpty else { return true }
        let pattern = #"^\d{2}/\d{2}/\d{4}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }

    func applySoftwareLastSixMonthsPreset() {
        let now = Date()
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        searchText = "Software"
        postedFrom = formatDate(sixMonthsAgo)
        postedTo = formatDate(now)
    }

    func applyNAICSPreset(code: String, title: String) {
        let now = Date()
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        searchText = title
        naics = code
        postedFrom = formatDate(sixMonthsAgo)
        postedTo = formatDate(now)
    }

    func search() async {
        if DebugSettings.shared.isEnabled {
            let currentText = searchText
            let currentPostedFrom = postedFrom
            let currentPostedTo = postedTo
            let currentNaics = naics
            let currentAgency = agency
            let currentNoticeType = noticeType
            let currentSetAside = setAsideCode
            let currentSort = sortOption.sort
            let currentOrder = sortOption.order
            logger.debug("search start text=\(currentText, privacy: .public) postedFrom=\(currentPostedFrom ?? "nil", privacy: .public) postedTo=\(currentPostedTo ?? "nil", privacy: .public) naics=\(currentNaics ?? "nil", privacy: .public) agency=\(currentAgency ?? "nil", privacy: .public) noticeType=\(currentNoticeType ?? "nil", privacy: .public) setAside=\(currentSetAside ?? "nil", privacy: .public) sort=\(currentSort, privacy: .public) order=\(currentOrder, privacy: .public)")
        }
        isLoading = true
        error = nil
        opportunities = []
        totalRecords = 0
        offset = 0

        if !isValidDate(postedFrom) || !isValidDate(postedTo) {
            error = "Invalid Date Entered. Expected date format is MM/dd/yyyy."
            if DebugSettings.shared.isEnabled {
                let currentPostedFrom = postedFrom
                let currentPostedTo = postedTo
                logger.error("search invalid date format postedFrom=\(currentPostedFrom ?? "nil", privacy: .public) postedTo=\(currentPostedTo ?? "nil", privacy: .public)")
            }
            isLoading = false
            return
        }
        if (postedFrom ?? "").isEmpty || (postedTo ?? "").isEmpty {
            error = "Posted From and Posted To are required."
            if DebugSettings.shared.isEnabled {
                let currentPostedFrom = postedFrom
                let currentPostedTo = postedTo
                logger.error("search missing required dates postedFrom=\(currentPostedFrom ?? "nil", privacy: .public) postedTo=\(currentPostedTo ?? "nil", privacy: .public)")
            }
            isLoading = false
            return
        }

        do {
            let response = try await SAMAPIClient.shared
                .fetchOpportunities(
                    query: searchText,
                    postedFrom: postedFrom,
                    postedTo: postedTo,
                    naics: naics,
                    agency: agency,
                    noticeType: noticeType,
                    setAsideCode: setAsideCode,
                    sort: sortOption.sort,
                    order: sortOption.order,
                    limit: pageSize,
                    offset: offset
                )
            opportunities = response.opportunitiesData
            totalRecords = response.totalRecords ?? response.opportunitiesData.count
            if DebugSettings.shared.isEnabled {
                let count = opportunities.count
                logger.debug("search success count=\(count)")
            }
        } catch let caughtError {
            if let apiError = caughtError as? SAMAPIClient.APIError {
                error = apiError.localizedDescription
            } else {
                error = "Failed to load contracts."
            }
            if DebugSettings.shared.isEnabled {
                logger.error("search failed error=\(caughtError.localizedDescription, privacy: .public)")
            }
        }

        isLoading = false
        if DebugSettings.shared.isEnabled {
            let loading = isLoading
            logger.debug("search end isLoading=\(loading)")
        }
    }

    func scheduleAutoSearch() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard let self else { return }
            await self.search()
        }
    }

    func loadMore() async {
        if let lastLoadMoreAt, Date().timeIntervalSince(lastLoadMoreAt) < 0.8 {
            return
        }
        guard !isLoadingMore, canLoadMore else { return }
        isLoadingMore = true
        lastLoadMoreAt = Date()
        error = nil

        let nextOffset = opportunities.count
        do {
            let response = try await SAMAPIClient.shared
                .fetchOpportunities(
                    query: searchText,
                    postedFrom: postedFrom,
                    postedTo: postedTo,
                    naics: naics,
                    agency: agency,
                    noticeType: noticeType,
                    setAsideCode: setAsideCode,
                    sort: sortOption.sort,
                    order: sortOption.order,
                    limit: pageSize,
                    offset: nextOffset
                )
            opportunities.append(contentsOf: response.opportunitiesData)
            totalRecords = response.totalRecords ?? max(totalRecords, opportunities.count)
            offset = nextOffset
            if DebugSettings.shared.isEnabled {
                let count = opportunities.count
                logger.debug("loadMore success count=\(count)")
            }
        } catch let caughtError {
            if let apiError = caughtError as? SAMAPIClient.APIError {
                error = apiError.localizedDescription
            } else {
                error = "Failed to load more contracts."
            }
            if DebugSettings.shared.isEnabled {
                logger.error("loadMore failed error=\(caughtError.localizedDescription, privacy: .public)")
            }
        }

        isLoadingMore = false
    }
}
