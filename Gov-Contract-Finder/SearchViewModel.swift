//
//  SearchViewModel.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import Observation

@Observable
final class SearchViewModel {

    var searchText: String = ""
    var opportunities: [Opportunity] = []
    var isLoading = false
    var error: String?

    var hasResults: Bool {
        !opportunities.isEmpty
    }

    func search() async {
        isLoading = true
        error = nil

        do {
            opportunities = try await SAMAPIClient.shared
                .fetchOpportunities(query: searchText)
        } catch {
            self.error = "Failed to load contracts."
        }

        isLoading = false
    }
}
