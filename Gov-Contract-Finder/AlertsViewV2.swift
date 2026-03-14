import SwiftUI

struct AlertsViewV2: View {
    @Bindable var alertsStore: AlertsStore

    var body: some View {
        SafeEdgeScrollColumn(maxContentWidth: 840) {
            header
            feedSection
            rulesSection
        }
        .background(CyberpunkBackgroundV2())
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
            HStack {
                Text("Alerts")
                    .font(DesignTokensV2.Typography.hero)
                    .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                Spacer()
                if alertsStore.unreadCount > 0 {
                    Button("Mark all read") {
                        alertsStore.markAllRead()
                    }
                    .font(DesignTokensV2.Typography.caption)
                    .foregroundStyle(DesignTokensV2.Colors.accentCyan)
                }
            }

            BoundedBodyText(value: "\(alertsStore.unreadCount) unread notifications")
        }
    }

    @ViewBuilder
    private var feedSection: some View {
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
                    HStack(alignment: .top, spacing: DesignTokensV2.Spacing.xs) {
                        Image(systemName: icon(for: alert.type))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(color(for: alert.type))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
                            BoundedBodyText(
                                value: alert.title,
                                font: DesignTokensV2.Typography.bodyStrong,
                                color: alert.isRead ? DesignTokensV2.Colors.textSecondary : DesignTokensV2.Colors.textPrimary
                            )
                            BoundedBodyText(value: alert.message)
                        }
                        Spacer()

                        BoundedBodyText(value: relativeDate(alert.createdAt), font: DesignTokensV2.Typography.caption)
                    }

                    HStack(spacing: DesignTokensV2.Spacing.xs) {
                        ActionPillV2(
                            title: alert.isRead ? "Mark Unread" : "Mark Read",
                            tint: DesignTokensV2.Colors.success
                        ) {
                            alertsStore.markRead(alert.id, isRead: !alert.isRead)
                        }

                        ActionPillV2(
                            title: "Dismiss",
                            tint: DesignTokensV2.Colors.danger
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
                    .font(DesignTokensV2.Typography.section)
                    .foregroundStyle(DesignTokensV2.Colors.textPrimary)

                Spacer()

                Button {
                    addRule()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("New Rule")
                    }
                    .font(DesignTokensV2.Typography.bodyStrong)
                    .foregroundStyle(DesignTokensV2.Colors.bg900)
                    .padding(.horizontal, DesignTokensV2.Spacing.s)
                    .padding(.vertical, DesignTokensV2.Spacing.xs)
                    .background(
                        Capsule(style: .continuous)
                            .fill(DesignTokensV2.Colors.accentCyan)
                    )
                }
                .buttonStyle(.plain)
            }

            ForEach(alertsStore.rules) { rule in
                VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
                    HStack {
                        BoundedBodyText(
                            value: ruleTitle(for: rule),
                            font: DesignTokensV2.Typography.bodyStrong,
                            color: DesignTokensV2.Colors.textPrimary
                        )

                        Spacer()

                        BadgeV2(
                            text: rule.enabled ? "Active" : "Paused",
                            color: rule.enabled ? DesignTokensV2.Colors.success : DesignTokensV2.Colors.textSecondary
                        )
                    }

                    HStack(spacing: DesignTokensV2.Spacing.xs) {
                        BadgeV2(text: rule.type.title.lowercased(), color: DesignTokensV2.Colors.accentCyan)
                        if !rule.keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            BadgeV2(text: rule.keyword.lowercased(), color: DesignTokensV2.Colors.accentViolet)
                        }
                    }

                    HStack(spacing: DesignTokensV2.Spacing.xs) {
                        ActionPillV2(
                            title: rule.enabled ? "Pause" : "Activate",
                            tint: rule.enabled ? DesignTokensV2.Colors.warning : DesignTokensV2.Colors.success
                        ) {
                            alertsStore.setRuleEnabled(id: rule.id, enabled: !rule.enabled)
                        }

                        ActionPillV2(title: "Delete", tint: DesignTokensV2.Colors.danger) {
                            alertsStore.rules.removeAll { $0.id == rule.id }
                        }

                        Spacer()
                    }
                }
                .padding(DesignTokensV2.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                        .fill(DesignTokensV2.Colors.surface2.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                        .stroke(DesignTokensV2.Colors.border.opacity(0.7), lineWidth: 1)
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
        case .newOpportunity: return DesignTokensV2.Colors.accentCyan
        case .deadline: return DesignTokensV2.Colors.warning
        case .statusChange: return DesignTokensV2.Colors.accentViolet
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
}
