import SwiftUI

struct AlertsView: View {
    @Bindable var alertsStore: AlertsStore
    var lastCheckedAt: Date? = nil
    var onOpenOpportunity: ((String) -> Void)? = nil

    var body: some View {
        SafeEdgeScrollColumn(maxContentWidth: 840) {
            header
            feedSection
            rulesSection
        }
        .background(CyberpunkBackground())
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text("Alerts")
                    .font(DesignTokens.Typography.hero)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()

                HStack(spacing: DesignTokens.Spacing.xs) {
                    if alertsStore.unreadCount > 0 {
                        ActionPill(
                            title: "Mark All Read",
                            tint: DesignTokens.Colors.accentCyan
                        ) {
                            alertsStore.markAllRead()
                        }
                    }

                    if !alertsStore.items.isEmpty {
                        ActionPill(
                            title: "Clear All",
                            tint: DesignTokens.Colors.danger,
                            confirmation: ActionConfirmation(
                                title: "Clear all alerts?",
                                message: "This removes every alert from your feed. Alert rules stay enabled.",
                                confirmLabel: "Clear All",
                                role: .destructive
                            )
                        ) {
                            alertsStore.clearAll()
                        }
                    }
                }
            }

            BoundedBodyText(value: "\(alertsStore.unreadCount) unread notifications")
            BoundedBodyText(value: lastCheckedDescription, font: DesignTokens.Typography.caption)
        }
    }

    @ViewBuilder
    private var feedSection: some View {
        if alertsStore.items.isEmpty {
            NeoCard {
                Text("No alerts yet")
                    .font(DesignTokens.Typography.section)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                BoundedBodyText(value: "Enable rules and run Discover searches to populate this feed.")
            }
        } else {
            ForEach(alertsStore.items) { alert in
                NeoCard {
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: icon(for: alert.type))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(color(for: alert.type))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            BoundedBodyText(
                                value: alert.title,
                                font: DesignTokens.Typography.bodyStrong,
                                color: alert.isRead ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.textPrimary
                            )
                            BoundedBodyText(value: alert.message)
                        }
                        Spacer()

                        BoundedBodyText(value: relativeDate(alert.createdAt), font: DesignTokens.Typography.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard let opportunityID = alert.opportunityID else { return }
                        alertsStore.markRead(alert.id, isRead: true)
                        onOpenOpportunity?(opportunityID)
                    }

                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ActionPill(
                            title: alert.isRead ? "Mark Unread" : "Mark Read",
                            tint: DesignTokens.Colors.success
                        ) {
                            alertsStore.markRead(alert.id, isRead: !alert.isRead)
                        }

                        ActionPill(
                            title: "Dismiss",
                            tint: DesignTokens.Colors.danger
                        ) {
                            alertsStore.delete(alert.id)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    private var rulesSection: some View {
        NeoCard {
            HStack {
                Text("Alert Rules")
                    .font(DesignTokens.Typography.section)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()

                Button {
                    addRule()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("New Rule")
                    }
                    .font(DesignTokens.Typography.bodyStrong)
                    .foregroundStyle(DesignTokens.Colors.bg900)
                    .padding(.horizontal, DesignTokens.Spacing.s)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        Capsule(style: .continuous)
                            .fill(DesignTokens.Colors.accentCyan)
                    )
                }
                .buttonStyle(.plain)
            }

            ForEach(alertsStore.rules) { rule in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        BoundedBodyText(
                            value: ruleTitle(for: rule),
                            font: DesignTokens.Typography.bodyStrong,
                            color: DesignTokens.Colors.textPrimary
                        )

                        Spacer()

                        Badge(
                            text: rule.enabled ? "Active" : "Paused",
                            color: rule.enabled ? DesignTokens.Colors.success : DesignTokens.Colors.textSecondary
                        )
                    }

                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Badge(text: rule.type.title.lowercased(), color: DesignTokens.Colors.accentCyan)
                        if !rule.keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Badge(text: rule.keyword.lowercased(), color: DesignTokens.Colors.accentViolet)
                        }
                    }

                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ActionPill(
                            title: rule.enabled ? "Pause" : "Activate",
                            tint: rule.enabled ? DesignTokens.Colors.warning : DesignTokens.Colors.success
                        ) {
                            alertsStore.setRuleEnabled(id: rule.id, enabled: !rule.enabled)
                        }

                        ActionPill(title: "Delete", tint: DesignTokens.Colors.danger) {
                            alertsStore.rules.removeAll { $0.id == rule.id }
                        }

                        Spacer()
                    }
                }
                .padding(DesignTokens.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                        .fill(DesignTokens.Colors.surface2.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                        .stroke(DesignTokens.Colors.border.opacity(0.7), lineWidth: 1)
                )
            }
        }
    }

    private func addRule() {
        let sequence = AlertType.allCases
        let nextType = sequence[alertsStore.rules.count % sequence.count]
        let rule = AlertRule(
            id: UUID().uuidString,
            type: nextType,
            enabled: true,
            keyword: nextType == .newOpportunity ? "software" : "",
            createdAt: Date()
        )
        alertsStore.rules.insert(rule, at: 0)
    }

    private func ruleTitle(for rule: AlertRule) -> String {
        switch rule.type {
        case .newOpportunity:
            return "Cloud & Cybersecurity"
        case .deadline:
            return "DOD Opportunities"
        case .statusChange:
            return "Data Analytics"
        }
    }

    private func color(for type: AlertType) -> Color {
        switch type {
        case .newOpportunity: return DesignTokens.Colors.accentCyan
        case .deadline: return DesignTokens.Colors.warning
        case .statusChange: return DesignTokens.Colors.accentViolet
        }
    }

    private func icon(for type: AlertType) -> String {
        switch type {
        case .newOpportunity: return "plus"
        case .deadline: return "clock"
        case .statusChange: return "bell"
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var lastCheckedDescription: String {
        guard let lastCheckedAt else { return "Not checked yet" }
        return "Last checked \(relativeDate(lastCheckedAt))"
    }
}
