//
//  APIEndpointsTests.swift
//  Gov-Contract-FinderTests
//
//  Created by Fredy lopez on 2/12/26.
//

import Foundation
import Testing
@testable import Gov_Contract_Finder

struct APIEndpointsTests {
    @Test func includesAgencyQueryParameter() {
        let url = APIEndpoints.opportunities(
            apiKey: "key",
            query: "software",
            postedFrom: "01/01/2026",
            postedTo: "02/01/2026",
            naics: "541511",
            agency: "Department of Example",
            noticeType: nil,
            setAsideCode: nil,
            sort: "postedDate",
            order: "desc",
            limit: 25,
            offset: 0
        )
        #expect(url != nil)
        let query = url?.query ?? ""
        #expect(query.contains("department=Department%20of%20Example"))
    }
}
