//
//  Opportunity.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import Foundation

struct Opportunity: Identifiable, Decodable {
    let id: String
    let title: String
    let agency: String?
    let postedDate: String?
    let description: String?
    let solicitationNumber: String?
    let fullParentPathName: String?
    let fullParentPathCode: String?
    let office: String?
    let uiLink: String?
    let additionalInfoLink: String?
    let resourceLinks: [String]?
    let responseDate: String?
    let setAsideCode: String?
    let naicsCode: String?
    let naicsDescription: String?
    let contactEmail: String?
    let contactName: String?
    let contactPhone: String?
    let contacts: [Contact]

    enum CodingKeys: String, CodingKey {
        case id = "noticeId"
        case title
        case agency = "department"
        case postedDate
        case description
        case solicitationNumber
        case fullParentPathName
        case fullParentPathCode
        case office
        case uiLink
        case additionalInfoLink
        case resourceLinks
        case responseDate
        case setAsideCode
        case naicsCode
        case naicsDescription
        case pointOfContact
        case data
    }

    enum DataKeys: String, CodingKey {
        case pointOfContact
    }

    struct PointOfContact: Decodable {
        let type: String?
        let title: String?
        let fullName: String?
        let email: String?
        let phone: String?
        let fax: String?
    }

    struct Contact: Identifiable, Hashable {
        let id: String
        let type: String?
        let title: String?
        let fullName: String?
        let email: String?
        let phone: String?
        let fax: String?
    }

    init(
        id: String,
        title: String,
        agency: String? = nil,
        postedDate: String? = nil,
        description: String? = nil,
        solicitationNumber: String? = nil,
        fullParentPathName: String? = nil,
        fullParentPathCode: String? = nil,
        office: String? = nil,
        uiLink: String? = nil,
        additionalInfoLink: String? = nil,
        resourceLinks: [String]? = nil,
        responseDate: String? = nil,
        setAsideCode: String? = nil,
        naicsCode: String? = nil,
        naicsDescription: String? = nil,
        contactEmail: String? = nil,
        contactName: String? = nil,
        contactPhone: String? = nil,
        contacts: [Contact] = []
    ) {
        self.id = id
        self.title = title
        self.agency = agency
        self.postedDate = postedDate
        self.description = description
        self.solicitationNumber = solicitationNumber
        self.fullParentPathName = fullParentPathName
        self.fullParentPathCode = fullParentPathCode
        self.office = office
        self.uiLink = uiLink
        self.additionalInfoLink = additionalInfoLink
        self.resourceLinks = resourceLinks
        self.responseDate = responseDate
        self.setAsideCode = setAsideCode
        self.naicsCode = naicsCode
        self.naicsDescription = naicsDescription
        self.contactEmail = contactEmail
        self.contactName = contactName
        self.contactPhone = contactPhone
        self.contacts = contacts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        agency = try container.decodeIfPresent(String.self, forKey: .agency)
        postedDate = try container.decodeIfPresent(String.self, forKey: .postedDate)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        solicitationNumber = try container.decodeIfPresent(String.self, forKey: .solicitationNumber)
        fullParentPathName = try container.decodeIfPresent(String.self, forKey: .fullParentPathName)
        fullParentPathCode = try container.decodeIfPresent(String.self, forKey: .fullParentPathCode)
        office = try container.decodeIfPresent(String.self, forKey: .office)
        uiLink = try container.decodeIfPresent(String.self, forKey: .uiLink)
        additionalInfoLink = try container.decodeIfPresent(String.self, forKey: .additionalInfoLink)
        resourceLinks = try container.decodeIfPresent([String].self, forKey: .resourceLinks)
        responseDate = try container.decodeIfPresent(String.self, forKey: .responseDate)
        setAsideCode = try container.decodeIfPresent(String.self, forKey: .setAsideCode)
        naicsCode = try container.decodeIfPresent(String.self, forKey: .naicsCode)
        naicsDescription = try container.decodeIfPresent(String.self, forKey: .naicsDescription)

        let directContacts = try container.decodeIfPresent([PointOfContact].self, forKey: .pointOfContact)
        let dataContacts: [PointOfContact]? = {
            guard let dataContainer = try? container.nestedContainer(keyedBy: DataKeys.self, forKey: .data) else {
                return nil
            }
            return try? dataContainer.decodeIfPresent([PointOfContact].self, forKey: .pointOfContact)
        }()

        let allContacts = directContacts ?? dataContacts ?? []
        let primary = allContacts.first { $0.type?.lowercased() == "primary" } ?? allContacts.first
        contactEmail = primary?.email
        contactName = primary?.fullName
        contactPhone = primary?.phone
        contacts = allContacts.map {
            Contact(
                id: UUID().uuidString,
                type: $0.type,
                title: $0.title,
                fullName: $0.fullName,
                email: $0.email,
                phone: $0.phone,
                fax: $0.fax
            )
        }
    }
}
