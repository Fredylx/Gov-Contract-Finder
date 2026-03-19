import SwiftUI
import UIKit

struct SafeEdgeScrollColumn<Content: View>: View {
    private let spacing: CGFloat
    private let horizontalPadding: CGFloat
    private let bottomPadding: CGFloat
    private let maxContentWidth: CGFloat
    private let content: () -> Content

    init(
        spacing: CGFloat = DesignTokens.Spacing.m,
        horizontalPadding: CGFloat = DesignTokens.Spacing.safeHorizontal,
        bottomPadding: CGFloat = DesignTokens.Spacing.xxl + 70,
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
            .padding(.top, DesignTokens.Spacing.m)
            .padding(.bottom, bottomPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scrollIndicators(.hidden)
    }
}

struct BoundedBodyText: View {
    let value: String
    var font: Font = DesignTokens.Typography.body
    var color: Color = DesignTokens.Colors.textSecondary

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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            content()
        }
        .padding(DesignTokens.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.surface.opacity(0.95),
                            DesignTokens.Colors.bg800.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .stroke(DesignTokens.Colors.accentCyan.opacity(0.38), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .inset(by: 1)
                .stroke(DesignTokens.Colors.border.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: DesignTokens.Colors.accentCyan.opacity(0.17), radius: 16, y: 6)
    }
}

struct NeonButton: View {
    let title: String
    let icon: String?
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(DesignTokens.Typography.bodyStrong)
            .foregroundStyle(DesignTokens.Colors.bg900)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                    .fill(enabled ? DesignTokens.Colors.accentCyan : DesignTokens.Colors.textSecondary.opacity(0.4))
            )
            .shadow(color: enabled ? DesignTokens.Colors.accentCyan.opacity(0.25) : .clear, radius: 12)
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
                .foregroundStyle(selected ? DesignTokens.Colors.bg900 : DesignTokens.Colors.accentCyan)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                        .fill(selected ? DesignTokens.Colors.accentCyan : DesignTokens.Colors.surface2)
                )
        }
        .accessibilityLabel(accessibilityLabel)
        .buttonStyle(.plain)
    }
}

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.s)
                .padding(.vertical, DesignTokens.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                        .fill(DesignTokens.Colors.bg800.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                        .stroke(DesignTokens.Colors.border, lineWidth: 1)
                )
        }
    }
}

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, DesignTokens.Spacing.s)
            .padding(.vertical, DesignTokens.Spacing.xs)
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

struct FilterChip: View {
    let title: String
    var selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(selected ? DesignTokens.Colors.bg900 : DesignTokens.Colors.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.s)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? DesignTokens.Colors.accentCyan : DesignTokens.Colors.surface2)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ActionConfirmation {
    let title: String
    let message: String
    let confirmLabel: String
    var role: ButtonRole? = nil
}

struct ActionPill: View {
    let title: String
    let tint: Color
    var icon: String? = nil
    var confirmation: ActionConfirmation? = nil
    let action: () -> Void

    @State private var isShowingConfirmation = false

    var body: some View {
        if let confirmation {
            buttonLabel
                .alert(confirmation.title, isPresented: $isShowingConfirmation) {
                    Button(confirmation.confirmLabel, role: confirmation.role) {
                        action()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(confirmation.message)
                }
        } else {
            buttonLabel
        }
    }

    private var buttonLabel: some View {
        Button {
            if confirmation != nil {
                isShowingConfirmation = true
            } else {
                action()
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, DesignTokens.Spacing.s)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.15))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ContactRow: View {
    let contact: Opportunity.Contact

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
                if let name = contact.fullName, !name.isEmpty {
                    BoundedBodyText(value: name, font: DesignTokens.Typography.bodyStrong, color: DesignTokens.Colors.textPrimary)
                }
                Spacer(minLength: 8)
                if let type = contact.type, !type.isEmpty {
                    Text(type.capitalized)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .padding(.horizontal, DesignTokens.Spacing.xs)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(DesignTokens.Colors.accentViolet.opacity(0.35))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(DesignTokens.Colors.accentViolet.opacity(0.7), lineWidth: 1)
                        )
                }
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
        .padding(DesignTokens.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                .fill(DesignTokens.Colors.surface2.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                .stroke(DesignTokens.Colors.border.opacity(0.8), lineWidth: 1)
        )
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
