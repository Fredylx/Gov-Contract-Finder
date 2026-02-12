//
//  PaginationTests.swift
//  Gov-Contract-FinderTests
//
//  Created by Fredy lopez on 2/12/26.
//

import Testing
@testable import Gov_Contract_Finder

struct PaginationTests {
    @Test func includesOffsetWhenProvided() {
        let url = APIEndpoints.opportunities(
            apiKey: "key",
            query: "software",
            postedFrom: "01/01/2026",
            postedTo: "02/01/2026",
            naics: nil,
            agency: nil,
            noticeType: nil,
            setAsideCode: nil,
            sort: "postedDate",
            order: "desc",
            limit: 25,
            offset: 50
        )
        #expect(url != nil)
        let query = url?.query ?? ""
        #expect(query.contains("offset=50"))
    }
}
