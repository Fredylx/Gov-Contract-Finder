import SwiftUI
import UIKit

struct OpportunityDetailView: View {
    let opportunity: Opportunity
    private let apiKey = APIKeyProvider.samKey()
    @State private var showCopied = false
    @State private var descriptionText: String? = nil
    @State private var isLoadingDescription = false
    @State private var descriptionUnavailableMessage: String? = nil

    var body: some View {
        ZStack {
            LuxuryBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                    Text(opportunity.title)
                        .font(DesignSystem.Typography.titleL)
                        .foregroundStyle(DesignSystem.Colors.primaryText)

                    SectionCard {
                        if let agency = opportunity.agency {
                            DetailRow(label: "Agency", value: agency)
                        }

                        if let office = opportunity.office {
                            DetailRow(label: "Office", value: office)
                        }

                        if let parentName = opportunity.fullParentPathName {
                            DetailRow(label: "Parent Path", value: parentName)
                        }

                        if let parentCode = opportunity.fullParentPathCode {
                            DetailRow(label: "Parent Code", value: parentCode)
                        }

                        if let solicitationNumber = opportunity.solicitationNumber {
                            DetailRow(label: "Solicitation #", value: solicitationNumber)
                        }

                        if let postedDate = opportunity.postedDate {
                            DetailRow(label: "Posted", value: formatDate(postedDate) ?? postedDate)
                        }

                        if let responseDate = opportunity.responseDate {
                            DetailRow(label: "Response Due", value: formatDate(responseDate) ?? responseDate)
                        }

                        if let naicsCode = opportunity.naicsCode {
                            if let naicsDescription = opportunity.naicsDescription {
                                DetailRow(label: "NAICS", value: "\(naicsCode) — \(naicsDescription)")
                            } else {
                                DetailRow(label: "NAICS", value: naicsCode)
                            }
                        }

                        if let setAsideCode = opportunity.setAsideCode {
                            DetailRow(label: "Set-Aside", value: setAsideCode)
                        }
                    }

                    if !opportunity.contacts.isEmpty {
                        SectionCard {
                            SectionHeader("Contacts")
                            if let emailLinkLabel = emailLinkLabel(for: opportunity.contacts),
                               let emailAllURL = mailtoURL(
                                   to: primaryEmail(from: opportunity.contacts),
                                   cc: ccEmails(from: opportunity.contacts),
                                   subject: "Contract Opportunity: \(opportunity.title)",
                                   body: emailBody(for: opportunity)
                               ) {
                                Link(emailLinkLabel, destination: emailAllURL)
                                    .font(DesignSystem.Typography.body.weight(.semibold))
                                    .foregroundStyle(DesignSystem.Colors.accentTeal)
                                    .accessibilityLabel(emailLinkLabel)
                            }
                            ForEach(opportunity.contacts) { contact in
                                VStack(alignment: .leading, spacing: 4) {
                                    if let name = contact.fullName {
                                        Text(name)
                                            .font(DesignSystem.Typography.body.weight(.semibold))
                                    }
                                    if let title = contact.title, !title.isEmpty {
                                        Text(title)
                                            .font(DesignSystem.Typography.body)
                                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                                    }
                                    if let type = contact.type, !type.isEmpty {
                                        Text("Type: \(type)")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                                    }
                                    if let email = contact.email {
                                        Text("Email: \(email)")
                                            .font(DesignSystem.Typography.body)
                                    }
                                if let phone = contact.phone, !phone.isEmpty {
                                    Text("Phone: \(phone)")
                                        .font(DesignSystem.Typography.body)
                                    if let telURL = telURL(phone) {
                                        Link("Call \(phone)", destination: telURL)
                                            .font(DesignSystem.Typography.body.weight(.semibold))
                                            .foregroundStyle(DesignSystem.Colors.accentNavy)
                                            .accessibilityLabel("Call \(phone)")
                                    }
                                }
                                    if let fax = contact.fax, !fax.isEmpty {
                                        Text("Fax: \(fax)")
                                            .font(DesignSystem.Typography.body)
                                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    } else {
                        SectionCard {
                            SectionHeader("Contacts")
                            if let contactName = opportunity.contactName {
                                DetailRow(label: "Contact", value: contactName)
                            }

                            if let contactEmail = opportunity.contactEmail {
                                DetailRow(label: "Email", value: contactEmail)
                                if let emailLinkLabel = emailLinkLabel(for: opportunity),
                                   let mailURL = mailtoURL(
                                       to: contactEmail,
                                       cc: [],
                                       subject: "Contract Opportunity: \(opportunity.title)",
                                       body: emailBody(for: opportunity)
                                   ) {
                                    Link(emailLinkLabel, destination: mailURL)
                                        .font(DesignSystem.Typography.body.weight(.semibold))
                                        .foregroundStyle(DesignSystem.Colors.accentTeal)
                                        .accessibilityLabel(emailLinkLabel)
                                }
                            }

                            if let contactPhone = opportunity.contactPhone {
                                DetailRow(label: "Phone", value: contactPhone)
                                if let tel = telURL(contactPhone) {
                                    Link("Call \(contactPhone)", destination: tel)
                                        .font(DesignSystem.Typography.body.weight(.semibold))
                                        .foregroundStyle(DesignSystem.Colors.accentNavy)
                                        .accessibilityLabel("Call \(contactPhone)")
                                }
                            }
                        }
                    }

                    let descriptionLink = opportunity.description
                    if let descriptionLink,
                       let url = buildURL(descriptionLink, apiKey: apiKey),
                       isLikelyURL(descriptionLink) {
                        SectionCard {
                            SectionHeader("Description")
                            if isLoadingDescription {
                                ProgressView("Loading description...")
                                    .padding(.top, 4)
                            } else if let descriptionText {
                                Text(descriptionText)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            } else if let descriptionUnavailableMessage {
                                Text(descriptionUnavailableMessage)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            } else {
                                Text("Unable to load description.")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                            CopyLinkButton(label: "Copy Description URL", url: url, showCopied: $showCopied)
                        }
                    }

                    if let description = opportunity.description, !isLikelyURL(description) {
                        SectionCard {
                            SectionHeader("Description")
                            Text(description)
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                    }

                    if let infoLink = opportunity.additionalInfoLink,
                       let url = buildURL(infoLink, apiKey: apiKey) {
                        SectionCard {
                            SectionHeader("Additional Info")
                            Link("Open Additional Info", destination: url)
                                .font(DesignSystem.Typography.body.weight(.semibold))
                                .foregroundStyle(DesignSystem.Colors.accentNavy)
                                .accessibilityLabel("Open additional info link")
                            ShareLink(item: url) {
                                Text("Share Additional Info")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                            CopyLinkButton(label: "Copy Additional Info URL", url: url, showCopied: $showCopied)
                        }
                    }

                    if let uiLink = opportunity.uiLink,
                       let url = URL(string: uiLink) {
                        SectionCard {
                            SectionHeader("SAM.gov")
                            Link("Open in SAM.gov", destination: url)
                                .font(DesignSystem.Typography.body.weight(.semibold))
                                .foregroundStyle(DesignSystem.Colors.accentNavy)
                                .accessibilityLabel("Open in SAM.gov")
                            ShareLink(item: url) {
                                Text("Share SAM.gov Link")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                            CopyLinkButton(label: "Copy SAM.gov URL", url: url, showCopied: $showCopied)
                        }
                    }

                    if let resourceLinks = opportunity.resourceLinks, !resourceLinks.isEmpty {
                        SectionCard {
                            SectionHeader("Attachments")
                            ForEach(resourceLinks, id: \.self) { link in
                                if let url = buildURL(link, apiKey: apiKey) {
                                    Link(linkLabel(for: url), destination: url)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundStyle(DesignSystem.Colors.accentNavy)
                                        .accessibilityLabel("Open attachment")
                                    ShareLink(item: url) {
                                        Text("Share Attachment")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                                    }
                                    CopyLinkButton(label: "Copy Attachment URL", url: url, showCopied: $showCopied)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding()
            }
        }
        .navigationTitle("Opportunity")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Copied to Clipboard", isPresented: $showCopied) {
            Button("OK", role: .cancel) {}
        }
        .task {
            await loadDescriptionIfNeeded()
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
            Text(value)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primaryText)
        }
    }
}

private struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(DesignSystem.Typography.titleM)
            .foregroundStyle(DesignSystem.Colors.primaryText)
            .padding(.top, 2)
    }
}

private struct SectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            content
        }
        .cardStyle()
    }
}

private func buildURL(_ string: String, apiKey: String?) -> URL? {
    guard var components = URLComponents(string: string) else { return nil }
    if let apiKey, !apiKey.isEmpty {
        var items = components.queryItems ?? []
        if !items.contains(where: { $0.name == "api_key" }) {
            items.append(URLQueryItem(name: "api_key", value: apiKey))
        }
        components.queryItems = items
    }
    return components.url
}

private func linkLabel(for url: URL) -> String {
    let last = url.lastPathComponent
    return last.isEmpty ? url.absoluteString : last
}

private func isLikelyURL(_ value: String) -> Bool {
    value.lowercased().hasPrefix("http://") || value.lowercased().hasPrefix("https://")
}

private func stripHTML(_ input: String) -> String {
    input.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
}

private extension OpportunityDetailView {
    func loadDescriptionIfNeeded() async {
        guard let descriptionLink = opportunity.description,
              isLikelyURL(descriptionLink),
              let url = buildURL(descriptionLink, apiKey: apiKey),
              descriptionText == nil,
              !isLoadingDescription
        else { return }

        isLoadingDescription = true
        defer { isLoadingDescription = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse,
               let contentType = http.value(forHTTPHeaderField: "Content-Type")?.lowercased() {
                if contentType.contains("application/pdf") {
                    descriptionUnavailableMessage = "Description is a PDF. Use the Description link above to open it."
                    descriptionText = nil
                    return
                }
                if !contentType.contains("text") && !contentType.contains("json") && !contentType.contains("xml") {
                    descriptionUnavailableMessage = "Description is not plain text. Use the Description link above to open it."
                    descriptionText = nil
                    return
                }
            }

            if let text = String(data: data, encoding: .utf8) {
                let cleaned = stripHTML(text).trimmingCharacters(in: .whitespacesAndNewlines)
                let normalized = normalizeDescription(cleaned)
                if cleaned.isEmpty {
                    descriptionUnavailableMessage = "Description is empty. Use the Description link above to open it."
                } else {
                    descriptionText = normalized
                    descriptionUnavailableMessage = nil
                }
            } else {
                descriptionUnavailableMessage = "Description is not readable text. Use the Description link above to open it."
                descriptionText = nil
            }
        } catch {
            descriptionUnavailableMessage = "Unable to load description. Use the Description link above to open it."
            descriptionText = nil
        }
    }
}

private func formatDate(_ value: String) -> String? {
    let inFormatter = DateFormatter()
    inFormatter.locale = Locale(identifier: "en_US_POSIX")
    inFormatter.dateFormat = "MM/dd/yyyy"

    let outFormatter = DateFormatter()
    outFormatter.locale = Locale(identifier: "en_US_POSIX")
    outFormatter.dateStyle = .medium
    outFormatter.timeStyle = .none

    if let date = inFormatter.date(from: value) {
        return outFormatter.string(from: date)
    }
    return nil
}

private func mailtoURL(_ email: String) -> URL? {
    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
    let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) ?? trimmed
    return URL(string: "mailto:\(encoded)")
}

private func mailtoURL(to: String?, cc: [String], subject: String?, body: String? = nil) -> URL? {
    guard let to, !to.isEmpty else { return nil }
    var components = URLComponents()
    components.scheme = "mailto"
    components.path = to

    var items: [URLQueryItem] = []
    if !cc.isEmpty {
        items.append(.init(name: "cc", value: cc.joined(separator: ",")))
    }
    if let subject, !subject.isEmpty {
        items.append(.init(name: "subject", value: subject))
    }
    if let body, !body.isEmpty {
        items.append(.init(name: "body", value: body))
    }
    components.queryItems = items.isEmpty ? nil : items
    return components.url
}

private func telURL(_ phone: String) -> URL? {
    let digits = phone.filter { $0.isNumber }
    guard !digits.isEmpty else { return nil }
    return URL(string: "tel:\(digits)")
}

private func emailLinkLabel(for contacts: [Opportunity.Contact]) -> String? {
    let emails = contacts.compactMap { $0.email }
    if emails.isEmpty { return nil }
    return emails.count == 1 ? "Email All Contacts" : "Email All Contacts (CC others)"
}

private func emailLinkLabel(for opportunity: Opportunity) -> String? {
    guard let email = opportunity.contactEmail, !email.isEmpty else { return nil }
    return "Email All Contacts"
}

private func primaryEmail(from contacts: [Opportunity.Contact]) -> String? {
    contacts.first { $0.type?.lowercased() == "primary" }?.email ?? contacts.first?.email
}

private func ccEmails(from contacts: [Opportunity.Contact]) -> [String] {
    var emails = contacts.compactMap { $0.email }
    if let primary = primaryEmail(from: contacts), let index = emails.firstIndex(of: primary) {
        emails.remove(at: index)
    }
    return emails
}

private func normalizeDescription(_ text: String) -> String {
    guard let data = text.data(using: .utf8) else { return text }
    guard let json = try? JSONSerialization.jsonObject(with: data) else { return text }
    let values = extractValues(from: json)
    if values.isEmpty { return text }
    return values.joined(separator: "\n")
}

private func emailBody(for opportunity: Opportunity) -> String {
    var lines: [String] = []
    lines.append("Hello,")
    lines.append("")
    lines.append("I’m interested in the following opportunity:")
    lines.append("- Title: \(opportunity.title)")
    if let solicitation = opportunity.solicitationNumber {
        lines.append("- Solicitation: \(solicitation)")
    }
    if let posted = opportunity.postedDate {
        lines.append("- Posted: \(formatDate(posted) ?? posted)")
    }
    if let uiLink = opportunity.uiLink {
        lines.append("- SAM.gov Link: \(uiLink)")
    }
    lines.append("")
    lines.append("Could you please share any additional details or guidance on next steps?")
    lines.append("")
    lines.append("Thank you,")
    return lines.joined(separator: "\n")
}

private func extractValues(from json: Any) -> [String] {
    if let dict = json as? [String: Any] {
        return dict.keys.sorted().flatMap { extractValues(from: dict[$0] as Any) }
    }
    if let array = json as? [Any] {
        return array.flatMap { extractValues(from: $0) }
    }
    if let string = json as? String {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? [] : [trimmed]
    }
    if let number = json as? NSNumber {
        return [number.stringValue]
    }
    return []
}

private struct CopyLinkButton: View {
    let label: String
    let url: URL
    @Binding var showCopied: Bool

    var body: some View {
        Button(label) {
            UIPasteboard.general.string = url.absoluteString
            showCopied = true
        }
        .font(DesignSystem.Typography.caption)
        .foregroundStyle(DesignSystem.Colors.secondaryText)
    }
}

#Preview {
    // Provide a local mock with only the properties used by the view, to avoid mismatched initializers.
    // If your real Opportunity type already has these properties, this initializer will compile.
    let sample = Opportunity(
        id: "1",
        title: "Software Development Services",
        agency: "Department of Example",
        postedDate: "01/15/2026",
        description: "This is a sample opportunity description.",
        solicitationNumber: "ABC-123",
        fullParentPathName: "Example Agency/Subdivision",
        fullParentPathCode: "EA/SD",
        office: "Office of Tech",
        uiLink: "https://sam.gov",
        additionalInfoLink: "https://example.com",
        resourceLinks: ["https://example.com/file.pdf"],
        responseDate: "02/01/2026",
        setAsideCode: "SBA",
        naicsCode: "541511",
        naicsDescription: "Custom Computer Programming Services",
        contacts: []
    )

    OpportunityDetailView(opportunity: sample)
}
