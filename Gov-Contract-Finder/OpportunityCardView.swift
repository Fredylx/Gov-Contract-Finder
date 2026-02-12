//
//  OpportunityCardView.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import SwiftUI
import OSLog

struct OpportunityCardView: View {
    let opportunity: Opportunity
    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "OpportunityCardView")

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(opportunity.title)
                .font(DesignSystem.Typography.titleM)
                .foregroundStyle(DesignSystem.Colors.primaryText)

            if let agency = opportunity.agency {
                Text(agency)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }

            if let postedDate = opportunity.postedDate {
                Text("Posted: \(postedDate)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .padding(.top, 2)
            }

            if let naicsCode = opportunity.naicsCode {
                Text("NAICS: \(naicsCode)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }

            if let description = opportunity.description {
                if !descriptionLooksLikeURL(description) {
                    Text(description)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .lineLimit(3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .onAppear {
            if DebugSettings.shared.isEnabled {
                logger.debug("render card id=\(opportunity.id, privacy: .public)")
            }
        }
    }

    private var accessibilitySummary: String {
        var parts: [String] = [opportunity.title]
        if let agency = opportunity.agency, !agency.isEmpty { parts.append(agency) }
        if let naics = opportunity.naicsCode, !naics.isEmpty { parts.append("NAICS \(naics)") }
        if let posted = opportunity.postedDate, !posted.isEmpty { parts.append("Posted \(posted)") }
        return parts.joined(separator: ", ")
    }
}

private func descriptionLooksLikeURL(_ value: String) -> Bool {
    value.lowercased().hasPrefix("http://") || value.lowercased().hasPrefix("https://")
}
