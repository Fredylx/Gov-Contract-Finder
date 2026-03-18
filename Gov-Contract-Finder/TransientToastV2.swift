import Observation
import SwiftUI

struct TransientToastMessageV2: Identifiable, Equatable {
    let id = UUID()
    var text: String
}

@MainActor
@Observable
final class TransientToastControllerV2 {
    var currentToast: TransientToastMessageV2?

    private var dismissTask: Task<Void, Never>?

    func show(text: String, autoDismissAfter duration: TimeInterval = 1.8) {
        dismissTask?.cancel()
        withAnimation(DesignTokensV2.Animation.quick) {
            currentToast = TransientToastMessageV2(text: text)
        }

        dismissTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            withAnimation(DesignTokensV2.Animation.quick) {
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

struct TransientToastViewV2: View {
    let message: String

    var body: some View {
        Text(message)
            .font(DesignTokensV2.Typography.caption)
            .foregroundStyle(DesignTokensV2.Colors.textPrimary)
            .padding(.horizontal, DesignTokensV2.Spacing.m)
            .padding(.vertical, DesignTokensV2.Spacing.s)
            .background(
                Capsule(style: .continuous)
                    .fill(DesignTokensV2.Colors.bg800.opacity(0.96))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DesignTokensV2.Colors.accentCyan.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: DesignTokensV2.Colors.accentCyan.opacity(0.2), radius: 16, y: 6)
            .allowsHitTesting(false)
    }
}
