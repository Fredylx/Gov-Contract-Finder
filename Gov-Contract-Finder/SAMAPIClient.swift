//
//  SAMAPIClient.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import Foundation

final class SAMAPIClient {

    static let shared = SAMAPIClient()
    private init() {}

    func fetchOpportunities(query: String) async throws -> [Opportunity] {
        guard let url = APIEndpoints.opportunities(
            apiKey: ProcessInfo.processInfo.environment["SAM_API_KEY"] ?? "",
            query: query
        ) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SAMResponse.self, from: data)
        return response.opportunitiesData
    }
}

struct SAMResponse: Decodable {
    let opportunitiesData: [Opportunity]
}
