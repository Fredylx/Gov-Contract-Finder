import SwiftUI
import UIKit

struct SafeEdgeScrollColumn<Content: View>: View {
    private let spacing: CGFloat
    private let horizontalPadding: CGFloat
    private let bottomPadding: CGFloat
    private let maxContentWidth: CGFloat
    private let content: () -> Content

    init(
        spacing: CGFloat = DesignTokensV2.Spacing.m,
        horizontalPadding: CGFloat = DesignTokensV2.Spacing.safeHorizontal,
        bottomPadding: CGFloat = DesignTokensV2.Spacing.xxl + 70,
        maxContentWidth: CGFloat = 760,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.bottomPadding = bottomPadding
        self.maxContentWidth = maxContentWidth
        self.content = content
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: spacing) {
                content()
            }
            .frame(maxWidth: maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, DesignTokensV2.Spacing.m)
            .padding(.bottom, bottomPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scrollIndicators(.hidden)
    }
}

struct BoundedBodyText: View {
    let value: String
    var font: Font = DesignTokensV2.Typography.body
    var color: Color = DesignTokensV2.Colors.textSecondary

    var body: some View {
        Text(OpportunityDetailTextFormatter.wrapUnsafeTokens(value))
            .font(font)
            .foregroundStyle(color)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .allowsTightening(true)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }
}

struct NeoCard<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.s) {
            content()
        }
        .padding(DesignTokensV2.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.card, style: .continuous)
                .fill(DesignTokensV2.Colors.surface.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.card, style: .continuous)
                .stroke(DesignTokensV2.Colors.border, lineWidth: 1)
        )
        .shadow(color: DesignTokensV2.Colors.accentCyan.opacity(0.12), radius: 12, y: 4)
    }
}

struct NeonButton: View {
    let title: String
    let icon: String?
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokensV2.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(DesignTokensV2.Typography.bodyStrong)
            .foregroundStyle(DesignTokensV2.Colors.bg900)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokensV2.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                    .fill(enabled ? DesignTokensV2.Colors.accentCyan : DesignTokensV2.Colors.textSecondary.opacity(0.4))
            )
            .shadow(color: enabled ? DesignTokensV2.Colors.accentCyan.opacity(0.25) : .clear, radius: 12)
        }
        .disabled(!enabled)
    }
}

struct NeonIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var selected: Bool = false
    var role: ButtonRole? = nil
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(selected ? DesignTokensV2.Colors.bg900 : DesignTokensV2.Colors.accentCyan)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                        .fill(selected ? DesignTokensV2.Colors.accentCyan : DesignTokensV2.Colors.surface2)
                )
        }
        .accessibilityLabel(accessibilityLabel)
        .buttonStyle(.plain)
    }
}

struct InputFieldV2: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xs) {
            Text(title)
                .font(DesignTokensV2.Typography.caption)
                .foregroundStyle(DesignTokensV2.Colors.textSecondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(DesignTokensV2.Typography.body)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                .padding(.horizontal, DesignTokensV2.Spacing.s)
                .padding(.vertical, DesignTokensV2.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                        .fill(DesignTokensV2.Colors.bg800.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                        .stroke(DesignTokensV2.Colors.border, lineWidth: 1)
                )
        }
    }
}

struct BadgeV2: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(DesignTokensV2.Typography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, DesignTokensV2.Spacing.s)
            .padding(.vertical, DesignTokensV2.Spacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.16))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
    }
}

struct FilterChipV2: View {
    let title: String
    var selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokensV2.Typography.caption)
                .foregroundStyle(selected ? DesignTokensV2.Colors.bg900 : DesignTokensV2.Colors.textPrimary)
                .padding(.horizontal, DesignTokensV2.Spacing.s)
                .padding(.vertical, DesignTokensV2.Spacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? DesignTokensV2.Colors.accentCyan : DesignTokensV2.Colors.surface2)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ContactRowV2: View {
    let contact: Opportunity.Contact

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xxs) {
            if let name = contact.fullName, !name.isEmpty {
                BoundedBodyText(value: name, font: DesignTokensV2.Typography.bodyStrong, color: DesignTokensV2.Colors.textPrimary)
            }

            if let title = contact.title, !title.isEmpty {
                BoundedBodyText(value: title)
            }

            if let email = contact.email, !email.isEmpty {
                BoundedBodyText(value: "Email: \(email)")
            }

            if let phone = contact.phone, !phone.isEmpty {
                BoundedBodyText(value: "Phone: \(phone)")
            }
        }
        .padding(.vertical, 4)
    }
}

struct KeyboardDismissOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(KeyboardDismissOnTapModifier())
    }
}
