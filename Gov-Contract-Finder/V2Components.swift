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
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokensV2.Colors.surface.opacity(0.95),
                            DesignTokensV2.Colors.bg800.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.card, style: .continuous)
                .stroke(DesignTokensV2.Colors.accentCyan.opacity(0.38), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.card, style: .continuous)
                .inset(by: 1)
                .stroke(DesignTokensV2.Colors.border.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: DesignTokensV2.Colors.accentCyan.opacity(0.17), radius: 16, y: 6)
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

struct ActionConfirmationV2 {
    let title: String
    let message: String
    let confirmLabel: String
    var role: ButtonRole? = nil
}

struct ActionPillV2: View {
    let title: String
    let tint: Color
    var icon: String? = nil
    var confirmation: ActionConfirmationV2? = nil
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
            HStack(spacing: DesignTokensV2.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(DesignTokensV2.Typography.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, DesignTokensV2.Spacing.s)
            .padding(.vertical, DesignTokensV2.Spacing.xs)
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

struct ContactRowV2: View {
    let contact: Opportunity.Contact

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokensV2.Spacing.xxs) {
            HStack(alignment: .top, spacing: DesignTokensV2.Spacing.xs) {
                if let name = contact.fullName, !name.isEmpty {
                    BoundedBodyText(value: name, font: DesignTokensV2.Typography.bodyStrong, color: DesignTokensV2.Colors.textPrimary)
                }
                Spacer(minLength: 8)
                if let type = contact.type, !type.isEmpty {
                    Text(type.capitalized)
                        .font(DesignTokensV2.Typography.caption)
                        .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                        .padding(.horizontal, DesignTokensV2.Spacing.xs)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(DesignTokensV2.Colors.accentViolet.opacity(0.35))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(DesignTokensV2.Colors.accentViolet.opacity(0.7), lineWidth: 1)
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
        .padding(DesignTokensV2.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                .fill(DesignTokensV2.Colors.surface2.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokensV2.Radius.button, style: .continuous)
                .stroke(DesignTokensV2.Colors.border.opacity(0.8), lineWidth: 1)
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
