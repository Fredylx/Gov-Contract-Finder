//
//  OpportunityDecodingTests.swift
//  Gov-Contract-FinderTests
//
//  Created by Fredy lopez on 2/12/26.
//

import Foundation
import Testing
@testable import Gov_Contract_Finder

struct OpportunityDecodingTests {
    @Test func decodesPrimaryContactFromPointOfContact() throws {
        let json = """
        {
          "noticeId": "123",
          "title": "Test Opportunity",
          "department": "Test Agency",
          "pointOfContact": [
            {
              "type": "primary",
              "fullName": "Jane Doe",
              "email": "jane@example.com",
              "phone": "555-1111"
            }
          ]
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(Opportunity.self, from: data)
        #expect(decoded.contactName == "Jane Doe")
        #expect(decoded.contactEmail == "jane@example.com")
        #expect(decoded.contactPhone == "555-1111")
        #expect(decoded.contacts.count == 1)
    }

    @Test func decodesContactFromNestedDataPointOfContact() throws {
        let json = """
        {
          "noticeId": "456",
          "title": "Nested Contact",
          "department": "Test Agency",
          "data": {
            "pointOfContact": [
              {
                "type": "primary",
                "fullName": "Alex Smith",
                "email": "alex@example.com",
                "phone": "555-2222"
              }
            ]
          }
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(Opportunity.self, from: data)
        #expect(decoded.contactName == "Alex Smith")
        #expect(decoded.contactEmail == "alex@example.com")
        #expect(decoded.contactPhone == "555-2222")
        #expect(decoded.contacts.count == 1)
    }
}
