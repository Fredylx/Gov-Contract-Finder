//
//  OpportunityCardView.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

struct OpportunityCardView: View {
    let opportunity: Opportunity

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
    }
}
