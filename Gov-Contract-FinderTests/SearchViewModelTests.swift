//
//  SearchViewModelTests.swift
//  Gov-Contract-FinderTests
//
//  Created by Fredy lopez on 2/12/26.
//

import Testing
@testable import Gov_Contract_Finder

struct SearchViewModelTests {
    @Test func sortOptionMappingPostedNewest() {
        let option = SearchViewModel.SortOption.postedNewest
        #expect(option.sort == "postedDate")
        #expect(option.order == "desc")
    }

    @Test func sortOptionMappingTitleAZ() {
        let option = SearchViewModel.SortOption.titleAZ
        #expect(option.sort == "title")
        #expect(option.order == "asc")
    }

    @Test func canLoadMoreReflectsTotalRecords() {
        let viewModel = SearchViewModel()
        viewModel.totalRecords = 100
        viewModel.opportunities = Array(repeating: Opportunity(id: "1", title: "Test"), count: 25)
        #expect(viewModel.canLoadMore == true)

        viewModel.opportunities = Array(repeating: Opportunity(id: "1", title: "Test"), count: 100)
        #expect(viewModel.canLoadMore == false)
    }
}
