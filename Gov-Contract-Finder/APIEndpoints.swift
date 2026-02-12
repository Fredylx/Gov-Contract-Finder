//
//  APIEndpoints.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import Foundation
import OSLog

enum APIEndpoints {
    static let baseURL = "https://api.sam.gov"
    private static let logger = Logger(subsystem: "Gov-Contract-Finder", category: "APIEndpoints")

    static func opportunities(
        apiKey: String,
        query: String,
        postedFrom: String? = nil,   // MM/dd/yyyy
        postedTo: String? = nil,     // MM/dd/yyyy
        naics: String? = nil,
        agency: String? = nil,
        noticeType: String? = nil,
        setAsideCode: String? = nil,
        sort: String? = "postedDate",
        order: String? = "desc",
        limit: Int = 25,
        offset: Int = 0
    ) -> URL? {
        var components = URLComponents(string: "\(baseURL)/opportunities/v2/search")
        var items: [URLQueryItem] = [
            .init(name: "api_key", value: apiKey),
            .init(name: "title", value: query),
            .init(name: "limit", value: String(limit))
        ]
        if let postedFrom { items.append(.init(name: "postedFrom", value: postedFrom)) }
        if let postedTo { items.append(.init(name: "postedTo", value: postedTo)) }
        if let naics { items.append(.init(name: "naics", value: naics)) }
        if let agency { items.append(.init(name: "department", value: agency)) }
        if let noticeType { items.append(.init(name: "noticeType", value: noticeType)) }
        if let setAsideCode { items.append(.init(name: "setAsideCode", value: setAsideCode)) }
        if let sort { items.append(.init(name: "sort", value: sort)) }
        if let order { items.append(.init(name: "order", value: order)) }
        if offset > 0 { items.append(.init(name: "offset", value: String(offset))) }
        components?.queryItems = items
        if DebugSettings.shared.isEnabled {
            if components?.url == nil {
                logger.error("opportunities endpoint failed to build URL")
            } else {
                let summary = items
                    .map { "\($0.name)=\($0.value ?? "nil")" }
                    .joined(separator: "&")
                logger.debug("opportunities endpoint built URL params=\(summary, privacy: .public)")
            }
        }
        return components?.url
    }
}
