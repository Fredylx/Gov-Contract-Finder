//
//  SAMAPIClient.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import Foundation
import OSLog

final class SAMAPIClient {

    static let shared = SAMAPIClient()
    private init() {}

    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "SAMAPIClient")

    private func clippedBody(_ data: Data, limit: Int = 2000) -> String? {
        guard !data.isEmpty else { return nil }
        if let text = String(data: data, encoding: .utf8) {
            return text.count > limit ? String(text.prefix(limit)) + "…" : text
        }
        return nil
    }

    private func headerSummary(_ response: HTTPURLResponse) -> String {
        let pairs = response.allHeaderFields.compactMap { key, value -> String? in
            guard let key = key as? String else { return nil }
            return "\(key)=\(value)"
        }
        return pairs.sorted().joined(separator: "; ")
    }

    enum APIError: LocalizedError {
        case missingAPIKey
        case badStatus(code: Int)
        case invalidQuery

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing SAM API Key. Add SAM_API_KEY in your Scheme Environment Variables or Info.plist."
            case .badStatus(let code):
                return "Server returned status code: \(code)."
            case .invalidQuery:
                return "Search text cannot be empty."
            }
        }
    }

    func fetchOpportunities(
        query: String,
        postedFrom: String? = nil,
        postedTo: String? = nil,
        naics: String? = nil,
        noticeType: String? = nil,
        setAsideCode: String? = nil,
        sort: String? = "postedDate",
        order: String? = "desc",
        limit: Int = 25,
        offset: Int = 0
    ) async throws -> SAMResponse {
        if DebugSettings.shared.isEnabled {
            logger.debug("fetchOpportunities start query=\(query, privacy: .public) limit=\(limit)")
        }
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if DebugSettings.shared.isEnabled {
                logger.error("fetchOpportunities invalid empty query")
            }
            throw APIError.invalidQuery
        }
        guard let apiKey = APIKeyProvider.samKey() else {
            if DebugSettings.shared.isEnabled {
                logger.error("fetchOpportunities missing API key")
            }
            throw APIError.missingAPIKey
        }

        guard let url = APIEndpoints.opportunities(
            apiKey: apiKey,
            query: query,
            postedFrom: postedFrom,
            postedTo: postedTo,
            naics: naics,
            noticeType: noticeType,
            setAsideCode: setAsideCode,
            sort: sort,
            order: order,
            limit: limit,
            offset: offset
        ) else {
            if DebugSettings.shared.isEnabled {
                logger.error("fetchOpportunities failed to build URL")
            }
            throw URLError(.badURL)
        }
        if DebugSettings.shared.isEnabled {
            logger.debug("fetchOpportunities url=\(url.absoluteString, privacy: .public)")
        }

        let start = Date()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if DebugSettings.shared.isEnabled {
            logger.debug("fetchOpportunities request method=\(request.httpMethod ?? "nil", privacy: .public)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let elapsed = Date().timeIntervalSince(start)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            if DebugSettings.shared.isEnabled {
                self.logger.error("fetchOpportunities bad status=\(http.statusCode) elapsed=\(elapsed, privacy: .public)")
                self.logger.error("fetchOpportunities headers=\(self.headerSummary(http), privacy: .public)")
                if let body = self.clippedBody(data) {
                    self.logger.error("fetchOpportunities response body=\(body, privacy: .public)")
                }
            }
            throw APIError.badStatus(code: http.statusCode)
        }
        if DebugSettings.shared.isEnabled {
            self.logger.debug("fetchOpportunities bytes=\(data.count) elapsed=\(elapsed, privacy: .public)")
            if let http = response as? HTTPURLResponse {
                self.logger.debug("fetchOpportunities headers=\(self.headerSummary(http), privacy: .public)")
            }
            if let body = self.clippedBody(data) {
                self.logger.debug("fetchOpportunities response body=\(body, privacy: .public)")
            }
        }

        do {
            let responseObj = try JSONDecoder().decode(SAMResponse.self, from: data)
            if DebugSettings.shared.isEnabled {
                self.logger.debug("fetchOpportunities decoded count=\(responseObj.opportunitiesData.count)")
            }
            return responseObj
        } catch {
            if DebugSettings.shared.isEnabled {
                self.logger.error("fetchOpportunities decode error=\(error.localizedDescription, privacy: .public)")
                if let body = self.clippedBody(data) {
                    self.logger.error("fetchOpportunities decode body=\(body, privacy: .public)")
                }
            }
            throw error
        }
    }
}

struct SAMResponse: Decodable {
    let opportunitiesData: [Opportunity]
    let totalRecords: Int?
    let limit: Int?
    let offset: Int?
}
