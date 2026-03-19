import Foundation
import SwiftUI

enum WatchStatus: String, CaseIterable, Codable, Identifiable {
    case new
    case reviewing
    case pursuing
    case submitted
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: return "New"
        case .reviewing: return "Reviewing"
        case .pursuing: return "Pursuing"
        case .submitted: return "Submitted"
        case .archived: return "Archived"
        }
    }
}

struct SavedOpportunitySnapshot: Codable, Hashable {
    struct SavedContact: Codable, Hashable {
        let id: String
        var type: String?
        var title: String?
        var fullName: String?
        var email: String?
        var phone: String?
        var fax: String?

        init(contact: Opportunity.Contact) {
            id = contact.id
            type = contact.type
            title = contact.title
            fullName = contact.fullName
            email = contact.email
            phone = contact.phone
            fax = contact.fax
        }

        var asOpportunityContact: Opportunity.Contact {
            Opportunity.Contact(
                id: id,
                type: type,
                title: title,
                fullName: fullName,
                email: email,
                phone: phone,
                fax: fax
            )
        }
    }

    let id: String
    var title: String
    var agency: String?
    var postedDate: String?
    var description: String?
    var solicitationNumber: String?
    var fullParentPathName: String?
    var fullParentPathCode: String?
    var office: String?
    var uiLink: String?
    var additionalInfoLink: String?
    var resourceLinks: [String]
    var responseDate: String?
    var setAsideCode: String?
    var naicsCode: String?
    var naicsDescription: String?
    var contactEmail: String?
    var contactName: String?
    var contactPhone: String?
    var contacts: [SavedContact]

    init(opportunity: Opportunity) {
        id = opportunity.id
        title = opportunity.title
        agency = opportunity.agency
        postedDate = opportunity.postedDate
        description = opportunity.description
        solicitationNumber = opportunity.solicitationNumber
        fullParentPathName = opportunity.fullParentPathName
        fullParentPathCode = opportunity.fullParentPathCode
        office = opportunity.office
        uiLink = opportunity.uiLink
        additionalInfoLink = opportunity.additionalInfoLink
        resourceLinks = opportunity.resourceLinks ?? []
        responseDate = opportunity.responseDate
        setAsideCode = opportunity.setAsideCode
        naicsCode = opportunity.naicsCode
        naicsDescription = opportunity.naicsDescription
        contactEmail = opportunity.contactEmail
        contactName = opportunity.contactName
        contactPhone = opportunity.contactPhone
        contacts = opportunity.contacts.map { SavedContact(contact: $0) }
    }

    init(legacyWatchlistItem: WatchlistItem) {
        id = legacyWatchlistItem.opportunityID
        title = legacyWatchlistItem.title
        agency = legacyWatchlistItem.agency
        postedDate = legacyWatchlistItem.postedDate
        let trimmedNotes = legacyWatchlistItem.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        description = trimmedNotes.isEmpty ? nil : trimmedNotes
        solicitationNumber = nil
        fullParentPathName = nil
        fullParentPathCode = nil
        office = nil
        uiLink = nil
        additionalInfoLink = nil
        resourceLinks = []
        responseDate = legacyWatchlistItem.responseDate
        setAsideCode = nil
        naicsCode = nil
        naicsDescription = nil
        contactEmail = nil
        contactName = nil
        contactPhone = nil
        contacts = []
    }

    var asOpportunity: Opportunity {
        Opportunity(
            id: id,
            title: title,
            agency: agency,
            postedDate: postedDate,
            description: description,
            solicitationNumber: solicitationNumber,
            fullParentPathName: fullParentPathName,
            fullParentPathCode: fullParentPathCode,
            office: office,
            uiLink: uiLink,
            additionalInfoLink: additionalInfoLink,
            resourceLinks: resourceLinks,
            responseDate: responseDate,
            setAsideCode: setAsideCode,
            naicsCode: naicsCode,
            naicsDescription: naicsDescription,
            contactEmail: contactEmail,
            contactName: contactName,
            contactPhone: contactPhone,
            contacts: contacts.map(\.asOpportunityContact)
        )
    }
}

struct WatchlistItem: Identifiable, Codable, Hashable {
    let id: String
    var opportunityID: String
    var title: String
    var agency: String
    var postedDate: String?
    var responseDate: String?
    var status: WatchStatus
    var notes: String
    var snapshot: SavedOpportunitySnapshot?
    var createdAt: Date
    var updatedAt: Date
}

enum AlertType: String, CaseIterable, Codable, Identifiable {
    case newOpportunity
    case deadline
    case statusChange

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newOpportunity: return "New Opportunity"
        case .deadline: return "Deadline"
        case .statusChange: return "Status Change"
        }
    }
}

struct AlertRule: Identifiable, Codable, Hashable {
    let id: String
    var type: AlertType
    var enabled: Bool
    var keyword: String
    var createdAt: Date
}

struct AlertItem: Identifiable, Codable, Hashable {
    let id: String
    var type: AlertType
    var title: String
    var message: String
    var opportunityID: String?
    var snapshot: SavedOpportunitySnapshot?
    var createdAt: Date
    var isRead: Bool
}

struct WorkspaceTask: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var completed: Bool
    var dueDate: Date?
}

struct WorkspaceNote: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var body: String
    var updatedAt: Date
}

struct WorkspaceDocument: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var url: String
    var addedAt: Date
}

struct WorkspaceActivity: Identifiable, Codable, Hashable {
    let id: String
    var text: String
    var createdAt: Date
}

struct WorkspaceRecord: Identifiable, Codable, Hashable {
    let id: String
    var opportunityID: String
    var opportunityTitle: String
    var snapshot: SavedOpportunitySnapshot?
    var tasks: [WorkspaceTask]
    var notes: [WorkspaceNote]
    var documents: [WorkspaceDocument]
    var activity: [WorkspaceActivity]
    var updatedAt: Date
}

enum AppearanceMode: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: SwiftUI.ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension WatchlistItem {
    var resolvedSnapshot: SavedOpportunitySnapshot {
        snapshot ?? SavedOpportunitySnapshot(legacyWatchlistItem: self)
    }

    var asOpportunity: Opportunity {
        resolvedSnapshot.asOpportunity
    }
}

extension AlertItem {
    var asOpportunity: Opportunity? {
        snapshot?.asOpportunity
    }
}
