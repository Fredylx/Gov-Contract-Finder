//
//  Opportunity.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

struct Opportunity: Identifiable, Decodable {
    let id: String
    let title: String
    let agency: String?
    let postedDate: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id = "noticeId"
        case title
        case agency = "department"
        case postedDate
        case description
    }
}
