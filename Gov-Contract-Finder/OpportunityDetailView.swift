import SwiftUI
import UIKit

struct OpportunityDetailView: View {
    let opportunity: Opportunity
    let watchlistStore: WatchlistStore
    let alertsStore: AlertsStore
    let workspaceStore: WorkspaceStore
    private let apiKey = APIKeyProvider.samKey()

    @State private var showCopied = false
    @State private var descriptionText: String? = nil
    @State private var isLoadingDescription = false
    @State private var descriptionUnavailableMessage: String? = nil

    @MainActor
    init(opportunity: Opportunity) {
        self.init(
            opportunity: opportunity,
            watchlistStore: .shared,
            alertsStore: .shared,
            workspaceStore: .shared
        )
    }

    @MainActor
    init(
        opportunity: Opportunity,
        watchlistStore: WatchlistStore,
        alertsStore: AlertsStore,
        workspaceStore: WorkspaceStore
    ) {
        self.opportunity = opportunity
        self.watchlistStore = watchlistStore
        self.alertsStore = alertsStore
        self.workspaceStore = workspaceStore
    }

    var body: some View {
        ZStack {
            CyberpunkBackgroundV2()

            SafeEdgeScrollColumn {
                headerCard
                metadataSection
                contactsSection
                descriptionSection
                additionalInfoSection
                samSection
                attachmentsSection
            }
            .accessibilityIdentifier("opportunity_detail_scroll")
        }
        .accessibilityIdentifier("opportunity_detail_screen")
        .navigationTitle("Opportunity")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Copied to Clipboard", isPresented: $showCopied) {
            Button("OK", role: .cancel) {}
        }
        .task {
            await loadDescriptionIfNeeded()
        }
    }

    private var headerCard: some View {
        NeoCard {
            BoundedBodyText(
                value: opportunity.title,
                font: DesignTokensV2.Typography.title,
                color: DesignTokensV2.Colors.textPrimary
            )

            if let solicitationNumber = opportunity.solicitationNumber, !solicitationNumber.isEmpty {
                BadgeV2(text: "Solicitation \(solicitationNumber)", color: DesignTokensV2.Colors.accentViolet)
            }

            HStack(spacing: DesignTokensV2.Spacing.s) {
                NeonButton(title: watchlistStore.contains(opportunityID: opportunity.id) ? "Saved" : "Save to Watchlist", icon: "bookmark") {
                    if !watchlistStore.contains(opportunityID: opportunity.id) {
                        watchlistStore.add(opportunity)
                        alertsStore.addAlert(
                            type: .statusChange,
                            title: "Watchlist Updated",
                            message: "Saved \(opportunity.title)",
                            opportunityID: opportunity.id
                        )
                    }
                }

                Button {
                    _ = workspaceStore.record(for: opportunity.id, fallbackTitle: opportunity.title)
                    alertsStore.addAlert(
                        type: .statusChange,
                        title: "Workspace Ready",
                        message: opportunity.title,
                        opportunityID: opportunity.id
                    )
                } label: {
                    Text("Open Workspace")
                        .font(DesignTokensV2.Typography.bodyStrong)
                        .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                        .padding(.horizontal, DesignTokensV2.Spacing.s)
                        .padding(.vertical, DesignTokensV2.Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                                .fill(DesignTokensV2.Colors.surface2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var metadataSection: some View {
        NeoCard {
            sectionHeader("Overview")

            if let agency = opportunity.agency {
                detailRow(label: "Agency", value: agency)
            }

            if let office = opportunity.office {
                detailRow(label: "Office", value: office)
            }

            if let parentName = opportunity.fullParentPathName {
                detailRow(label: "Parent Path", value: parentName)
            }

            if let parentCode = opportunity.fullParentPathCode {
                detailRow(label: "Parent Code", value: parentCode)
            }

            if let postedDate = opportunity.postedDate {
                detailRow(label: "Posted", value: formatDate(postedDate) ?? postedDate)
            }

            if let responseDate = opportunity.responseDate {
                detailRow(label: "Response Due", value: formatDate(responseDate) ?? responseDate)
            }

            if let naicsCode = opportunity.naicsCode {
                if let naicsDescription = opportunity.naicsDescription {
                    detailRow(label: "NAICS", value: "\(naicsCode) — \(naicsDescription)")
                } else {
                    detailRow(label: "NAICS", value: naicsCode)
                }
            }

            if let setAsideCode = opportunity.setAsideCode {
                detailRow(label: "Set-Aside", value: setAsideCode)
            }
        }
    }

    private var contactsSection: some View {
        NeoCard {
            sectionHeader("Contacts")

            if !opportunity.contacts.isEmpty {
                if let emailLinkLabel = emailLinkLabel(for: opportunity.contacts),
                   let emailAllURL = mailtoURL(
                    to: primaryEmail(from: opportunity.contacts),
                    cc: ccEmails(from: opportunity.contacts),
                    subject: "Contract Opportunity: \(opportunity.title)",
                    body: emailBody(for: opportunity)
                   ) {
                    Link(destination: emailAllURL) {
                        BoundedBodyText(
                            value: emailLinkLabel,
                            font: DesignTokensV2.Typography.bodyStrong,
                            color: DesignTokensV2.Colors.accentCyan
                        )
                    }
                    .accessibilityLabel(emailLinkLabel)
                }

                ForEach(opportunity.contacts) { contact in
                    ContactRowV2(contact: contact)
                }
            } else {
                fallbackContactDetails
            }
        }
    }

    @ViewBuilder
    private var fallbackContactDetails: some View {
        if let contactName = opportunity.contactName {
            detailRow(label: "Contact", value: contactName)
        }

        if let contactEmail = opportunity.contactEmail {
            detailRow(label: "Email", value: contactEmail)
        }

        if let contactPhone = opportunity.contactPhone {
            detailRow(label: "Phone", value: contactPhone)
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let descriptionValue = opportunity.description,
           isLikelyURL(descriptionValue),
           let url = buildURL(descriptionValue, apiKey: apiKey) {
            NeoCard {
                sectionHeader("Description")

                if isLoadingDescription {
                    ProgressView("Loading description...")
                        .tint(DesignTokensV2.Colors.accentCyan)
                } else if let descriptionText {
                    BoundedBodyText(value: descriptionText, color: DesignTokensV2.Colors.textPrimary)
                } else if let descriptionUnavailableMessage {
                    BoundedBodyText(value: descriptionUnavailableMessage)
                }

                Link(destination: url) {
                    BoundedBodyText(value: "Open Description URL", color: DesignTokensV2.Colors.accentCyan)
                }
                CopyLinkButton(label: "Copy Description URL", url: url, showCopied: $showCopied)
            }
        } else if let descriptionValue = opportunity.description {
            NeoCard {
                sectionHeader("Description")
                BoundedBodyText(
                    value: OpportunityDetailTextFormatter.descriptionDisplayText(from: descriptionValue),
                    color: DesignTokensV2.Colors.textPrimary
                )
            }
        }
    }

    @ViewBuilder
    private var additionalInfoSection: some View {
        if let infoLink = opportunity.additionalInfoLink,
           let url = buildURL(infoLink, apiKey: apiKey) {
            NeoCard {
                sectionHeader("Additional Info")

                Link(destination: url) {
                    BoundedBodyText(value: "Open Additional Info", color: DesignTokensV2.Colors.accentCyan)
                }

                ShareLink(item: url) {
                    Text("Share Additional Info")
                        .font(DesignTokensV2.Typography.caption)
                        .foregroundStyle(DesignTokensV2.Colors.textSecondary)
                }

                CopyLinkButton(label: "Copy Additional Info URL", url: url, showCopied: $showCopied)
            }
        }
    }

    @ViewBuilder
    private var samSection: some View {
        if let uiLink = opportunity.uiLink,
           let url = URL(string: uiLink) {
            NeoCard {
                sectionHeader("SAM.gov")

                Link(destination: url) {
                    BoundedBodyText(value: "Open in SAM.gov", color: DesignTokensV2.Colors.accentCyan)
                }

                ShareLink(item: url) {
                    Text("Share SAM.gov Link")
                        .font(DesignTokensV2.Typography.caption)
                        .foregroundStyle(DesignTokensV2.Colors.textSecondary)
                }

                CopyLinkButton(label: "Copy SAM.gov URL", url: url, showCopied: $showCopied)
            }
        }
    }

    @ViewBuilder
    private var attachmentsSection: some View {
        if let resourceLinks = opportunity.resourceLinks,
           !resourceLinks.isEmpty {
            NeoCard {
                sectionHeader("Attachments")
                ForEach(resourceLinks, id: \.self) { link in
                    if let url = buildURL(link, apiKey: apiKey) {
                        Link(destination: url) {
                            BoundedBodyText(
                                value: linkLabel(for: url),
                                color: DesignTokensV2.Colors.accentCyan
                            )
                        }

                        ShareLink(item: url) {
                            Text("Share Attachment")
                                .font(DesignTokensV2.Typography.caption)
                                .foregroundStyle(DesignTokensV2.Colors.textSecondary)
                        }

                        CopyLinkButton(label: "Copy Attachment URL", url: url, showCopied: $showCopied)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xxs) {
            Text(label)
                .font(DesignTokensV2.Typography.caption)
                .foregroundStyle(DesignTokensV2.Colors.textSecondary)
            BoundedBodyText(value: value, color: DesignTokensV2.Colors.textPrimary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignTokensV2.Typography.section)
            .foregroundStyle(DesignTokensV2.Colors.textPrimary)
    }

    private func loadDescriptionIfNeeded() async {
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
                    descriptionUnavailableMessage = "Description is a PDF. Use the description link above to open it."
                    return
                }
                if !contentType.contains("text") && !contentType.contains("json") && !contentType.contains("xml") {
                    descriptionUnavailableMessage = "Description is not plain text. Use the description link above to open it."
                    return
                }
            }

            if let text = String(data: data, encoding: .utf8) {
                let normalized = OpportunityDetailTextFormatter.descriptionDisplayText(from: text)
                if normalized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    descriptionUnavailableMessage = "Description is empty. Use the description link above to open it."
                } else {
                    descriptionText = normalized
                    descriptionUnavailableMessage = nil
                }
            } else {
                descriptionUnavailableMessage = "Description is not readable text. Use the description link above to open it."
            }
        } catch {
            descriptionUnavailableMessage = "Unable to load description. Use the description link above to open it."
        }
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

private func emailLinkLabel(for contacts: [Opportunity.Contact]) -> String? {
    let emails = contacts.compactMap { $0.email }
    if emails.isEmpty { return nil }
    return emails.count == 1 ? "Email Contact" : "Email All Contacts"
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

private func emailBody(for opportunity: Opportunity) -> String {
    var lines: [String] = []
    lines.append("Hello,")
    lines.append("")
    lines.append("I am interested in this opportunity:")
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
    lines.append("Could you share any additional details and next steps?")
    lines.append("")
    lines.append("Thank you,")
    return lines.joined(separator: "\n")
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
        .font(DesignTokensV2.Typography.caption)
        .foregroundStyle(DesignTokensV2.Colors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let sample = Opportunity(
        id: "1",
        title: "Modern Air Combat Environment software/license",
        agency: "DEPT OF DEFENSE",
        postedDate: "03/01/2026",
        description: "https://api.sam.gov/prod/opportunities/v1/noticedesc?noticeid=example",
        solicitationNumber: "W911S226U2708",
        fullParentPathName: "DEFENSE.DEPARTMENT OF THE ARMY.AMC.ACC.MISSION INSTALLATION CONTRACTING COMMAND",
        fullParentPathCode: "ARMY.AMC.ACC.MICC.419TH",
        office: "419TH CSB",
        uiLink: "https://sam.gov/workspace/contract/opp/example/view",
        additionalInfoLink: "https://sam.gov/example/info",
        resourceLinks: ["https://sam.gov/example/very_long_attachment_name_for_wrapping_test.pdf"],
        responseDate: "03/20/2026",
        setAsideCode: "Total Small Business",
        naicsCode: "541519",
        naicsDescription: "Other Computer Related Services",
        contacts: [
            Opportunity.Contact(
                id: "1",
                type: "primary",
                title: "Contracting Officer",
                fullName: "Faryn Duff",
                email: "faryn.p.duff.mil@army.mil",
                phone: "912-328-2620",
                fax: nil
            )
        ]
    )

    NavigationStack {
        OpportunityDetailView(opportunity: sample)
    }
}
