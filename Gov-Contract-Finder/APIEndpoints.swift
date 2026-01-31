//
//  APIEndpoints.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

enum APIEndpoints {
    static let baseURL = "https://api.sam.gov"

    static func opportunities(apiKey: String, query: String) -> URL? {
        var components = URLComponents(string: "\(baseURL)/opportunities/v2/search")
        components?.queryItems = [
            .init(name: "api_key", value: apiKey),
            .init(name: "title", value: query),
            .init(name: "limit", value: "25")
        ]
        return components?.url
    }
}
