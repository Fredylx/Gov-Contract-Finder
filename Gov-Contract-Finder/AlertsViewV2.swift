import SwiftUI

struct AlertsViewV2: View {
    @Bindable var alertsStore: AlertsStore

    var body: some View {
        SafeEdgeScrollColumn {
            rulesSection
            feedSection
        }
        .background(CyberpunkBackgroundV2())
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rulesSection: some View {
        NeoCard {
            HStack {
                Text("Alert Rules")
                    .font(DesignTokensV2.Typography.section)
                    .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                Spacer()
                BadgeV2(text: "\(alertsStore.unreadCount) unread", color: DesignTokensV2.Colors.accentCyan)
            }

            ForEach(alertsStore.rules) { rule in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        BoundedBodyText(
                            value: rule.type.title,
                            font: DesignTokensV2.Typography.bodyStrong,
                            color: DesignTokensV2.Colors.textPrimary
                        )
                        if !rule.keyword.isEmpty {
                            BoundedBodyText(value: "Keyword: \(rule.keyword)")
                        }
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { rule.enabled },
                        set: { alertsStore.setRuleEnabled(id: rule.id, enabled: $0) }
                    ))
                    .labelsHidden()
                    .tint(DesignTokensV2.Colors.accentCyan)
                }
            }

            HStack {
                Button("Simulate New Opportunity") {
                    alertsStore.addAlert(
                        type: .newOpportunity,
                        title: "Fresh Match",
                        message: "A new software opportunity matched your filters.")
                }
                .font(DesignTokensV2.Typography.caption)
                .foregroundStyle(DesignTokensV2.Colors.accentCyan)

                Spacer()

                Button("Mark All Read") {
                    alertsStore.markAllRead()
                }
                .font(DesignTokensV2.Typography.caption)
                .foregroundStyle(DesignTokensV2.Colors.textSecondary)
            }
        }
    }

    private var feedSection: some View {
        Group {
            if alertsStore.items.isEmpty {
                NeoCard {
                    Text("No alerts yet")
                        .font(DesignTokensV2.Typography.section)
                        .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                    BoundedBodyText(value: "Enable rules and run Discover searches to populate this feed.")
                }
            } else {
                ForEach(alertsStore.items) { alert in
                    NeoCard {
                        HStack(alignment: .top) {
                            Circle()
                                .fill(color(for: alert.type))
                                .frame(width: 10, height: 10)
                                .opacity(alert.isRead ? 0.45 : 1)

                            VStack(alignment: .leading, spacing: 4) {
                                BoundedBodyText(
                                    value: alert.title,
                                    font: DesignTokensV2.Typography.bodyStrong,
                                    color: alert.isRead ? DesignTokensV2.Colors.textSecondary : DesignTokensV2.Colors.textPrimary
                                )
                                BoundedBodyText(value: alert.message)
                                BoundedBodyText(value: relativeDate(alert.createdAt), font: DesignTokensV2.Typography.caption)
                            }

                            Spacer()
                        }

                        HStack {
                            Button(alert.isRead ? "Mark Unread" : "Mark Read") {
                                alertsStore.markRead(alert.id, isRead: !alert.isRead)
                            }
                            .font(DesignTokensV2.Typography.caption)
                            .foregroundStyle(DesignTokensV2.Colors.accentCyan)

                            Spacer()

                            Button("Delete") {
                                alertsStore.delete(alert.id)
                            }
                            .font(DesignTokensV2.Typography.caption)
                            .foregroundStyle(DesignTokensV2.Colors.danger)
                        }
                    }
                }
            }
        }
    }

    private func color(for type: AlertType) -> Color {
        switch type {
        case .newOpportunity: return DesignTokensV2.Colors.accentCyan
        case .deadline: return DesignTokensV2.Colors.warning
        case .statusChange: return DesignTokensV2.Colors.accentViolet
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
