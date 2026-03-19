import Foundation

struct OpportunitySearchFilters: Sendable, Equatable {
    var query: String = ""
    var postedFrom: String?
    var postedTo: String?
    var naics: String?
    var agency: String?
    var noticeType: String?
    var setAsideCode: String?
    var sort: String = "postedDate"
    var order: String = "desc"
}

struct OpportunitySearchPage: Sendable {
    var opportunities: [Opportunity]
    var totalRecords: Int
}

protocol OpportunityRepository {
    func search(filters: OpportunitySearchFilters, limit: Int, offset: Int) async throws -> OpportunitySearchPage
}

protocol SAMOpportunityFetching {
    func fetchOpportunities(
        query: String,
        postedFrom: String?,
        postedTo: String?,
        naics: String?,
        agency: String?,
        noticeType: String?,
        setAsideCode: String?,
        sort: String?,
        order: String?,
        limit: Int,
        offset: Int
    ) async throws -> SAMResponse
}

extension SAMAPIClient: SAMOpportunityFetching {}

struct SAMOpportunityRepository: OpportunityRepository {
    private let client: SAMOpportunityFetching

    init(client: SAMOpportunityFetching = SAMAPIClient.shared) {
        self.client = client
    }

    func search(filters: OpportunitySearchFilters, limit: Int, offset: Int) async throws -> OpportunitySearchPage {
        let response = try await client.fetchOpportunities(
            query: filters.query,
            postedFrom: filters.postedFrom,
            postedTo: filters.postedTo,
            naics: filters.naics,
            agency: filters.agency,
            noticeType: filters.noticeType,
            setAsideCode: filters.setAsideCode,
            sort: filters.sort,
            order: filters.order,
            limit: limit,
            offset: offset
        )

        return OpportunitySearchPage(
            opportunities: response.opportunitiesData,
            totalRecords: response.totalRecords ?? response.opportunitiesData.count
        )
    }
}
