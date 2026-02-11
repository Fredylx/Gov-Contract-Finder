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
        VStack(alignment: .leading, spacing: 6) {
            Text(opportunity.title)
                .font(.headline)

            if let agency = opportunity.agency {
                Text(agency)
                    .foregroundStyle(.secondary)
            }

            if let description = opportunity.description {
                Text(description)
                    .font(.subheadline)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            if DebugSettings.shared.isEnabled {
                logger.debug("render card id=\(opportunity.id, privacy: .public)")
            }
        }
    }
}
