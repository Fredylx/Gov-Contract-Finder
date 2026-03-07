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

struct WatchlistItem: Identifiable, Codable, Hashable {
    let id: String
    var opportunityID: String
    var title: String
    var agency: String
    var postedDate: String?
    var responseDate: String?
    var status: WatchStatus
    var notes: String
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
    var tasks: [WorkspaceTask]
    var notes: [WorkspaceNote]
    var documents: [WorkspaceDocument]
    var activity: [WorkspaceActivity]
    var updatedAt: Date
}

enum AppearanceModeV2: String, CaseIterable, Codable, Identifiable {
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
