import Observation
import SwiftUI

struct TransientToastMessage: Identifiable, Equatable {
    let id = UUID()
    var text: String
}

@MainActor
@Observable
final class TransientToastController {
    var currentToast: TransientToastMessage?

    private var dismissTask: Task<Void, Never>?

    func show(text: String, autoDismissAfter duration: TimeInterval = 1.8) {
        dismissTask?.cancel()
        withAnimation(DesignTokens.Animation.quick) {
            currentToast = TransientToastMessage(text: text)
        }

        dismissTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            withAnimation(DesignTokens.Animation.quick) {
                self.currentToast = nil
            }
            self.dismissTask = nil
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        currentToast = nil
    }
}

struct TransientToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textPrimary)
            .padding(.horizontal, DesignTokens.Spacing.m)
            .padding(.vertical, DesignTokens.Spacing.s)
            .background(
                Capsule(style: .continuous)
                    .fill(DesignTokens.Colors.bg800.opacity(0.96))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DesignTokens.Colors.accentCyan.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: DesignTokens.Colors.accentCyan.opacity(0.2), radius: 16, y: 6)
            .allowsHitTesting(false)
    }
}
