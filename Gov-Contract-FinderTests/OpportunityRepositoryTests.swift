import Testing
@testable import Gov_Contract_Finder

private actor MockSAMFetcher: SAMOpportunityFetching {
    struct CapturedRequest {
        let query: String
        let postedFrom: String?
        let postedTo: String?
        let naics: String?
        let agency: String?
        let noticeType: String?
        let setAsideCode: String?
        let sort: String?
        let order: String?
        let limit: Int
        let offset: Int
    }

    var capturedRequest: CapturedRequest?
    var response: SAMResponse

    init(response: SAMResponse) {
        self.response = response
    }

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
    ) async throws -> SAMResponse {
        capturedRequest = CapturedRequest(
            query: query,
            postedFrom: postedFrom,
            postedTo: postedTo,
            naics: naics,
            agency: agency,
            noticeType: noticeType,
            setAsideCode: setAsideCode,
            sort: sort,
            order: order,
            limit: limit,
            offset: offset
        )
        return response
    }

    func lastRequest() -> CapturedRequest? {
        capturedRequest
    }
}

struct OpportunityRepositoryTests {
    @Test func samRepositoryMapsResponseAndForwardsFilters() async throws {
        let sampleOpportunity = Opportunity(
            id: "notice-1",
            title: "Sample Opportunity",
            agency: "Test Agency",
            postedDate: "03/01/2026",
            description: "Sample",
            solicitationNumber: "ABC-123",
            contacts: []
        )

        let mock = MockSAMFetcher(
            response: SAMResponse(
                opportunitiesData: [sampleOpportunity],
                totalRecords: 42,
                limit: 25,
                offset: 0
            )
        )

        let repository = SAMOpportunityRepository(client: mock)
        let filters = OpportunitySearchFiltersV2(
            query: "software",
            postedFrom: "01/01/2026",
            postedTo: "03/01/2026",
            naics: "541519",
            agency: "Department",
            noticeType: "Presolicitation",
            setAsideCode: "SBA",
            sort: "postedDate",
            order: "desc"
        )

        let page = try await repository.search(filters: filters, limit: 25, offset: 0)
        let request = await mock.lastRequest()

        #expect(page.opportunities.count == 1)
        #expect(page.opportunities.first?.id == "notice-1")
        #expect(page.totalRecords == 42)

        #expect(request?.query == "software")
        #expect(request?.postedFrom == "01/01/2026")
        #expect(request?.postedTo == "03/01/2026")
        #expect(request?.naics == "541519")
        #expect(request?.agency == "Department")
        #expect(request?.noticeType == "Presolicitation")
        #expect(request?.setAsideCode == "SBA")
        #expect(request?.sort == "postedDate")
        #expect(request?.order == "desc")
        #expect(request?.limit == 25)
        #expect(request?.offset == 0)
    }
}
