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

    var searchText: String = ""
    var postedFrom: String? = nil
    var postedTo: String? = nil
    var naics: String? = nil
    var noticeType: String? = nil
    var setAsideCode: String? = nil
    var sort: String = "postedDate"
    var order: String = "desc"
    var opportunities: [Opportunity] = []
    var isLoading = false
    var error: String?

    var hasResults: Bool {
        !opportunities.isEmpty
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

    func search() async {
        if DebugSettings.shared.isEnabled {
            let currentText = searchText
            let currentPostedFrom = postedFrom
            let currentPostedTo = postedTo
            let currentNaics = naics
            let currentNoticeType = noticeType
            let currentSetAside = setAsideCode
            let currentSort = sort
            let currentOrder = order
            logger.debug("search start text=\(currentText, privacy: .public) postedFrom=\(currentPostedFrom ?? "nil", privacy: .public) postedTo=\(currentPostedTo ?? "nil", privacy: .public) naics=\(currentNaics ?? "nil", privacy: .public) noticeType=\(currentNoticeType ?? "nil", privacy: .public) setAside=\(currentSetAside ?? "nil", privacy: .public) sort=\(currentSort, privacy: .public) order=\(currentOrder, privacy: .public)")
        }
        isLoading = true
        error = nil
        opportunities = []

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
            opportunities = try await SAMAPIClient.shared
                .fetchOpportunities(
                    query: searchText,
                    postedFrom: postedFrom,
                    postedTo: postedTo,
                    naics: naics,
                    noticeType: noticeType,
                    setAsideCode: setAsideCode,
                    sort: sort,
                    order: order
                )
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
}
