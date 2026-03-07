import SwiftUI

enum DesignTokensV2 {
    enum Colors {
        static let bg900 = Color(hex: "050816")
        static let bg800 = Color(hex: "0B1026")
        static let surface = Color(hex: "121A34")
        static let surface2 = Color(hex: "182247")
        static let textPrimary = Color(hex: "EAF2FF")
        static let textSecondary = Color(hex: "9FB0D1")
        static let accentCyan = Color(hex: "2DE2E6")
        static let accentMagenta = Color(hex: "FF4FD8")
        static let accentViolet = Color(hex: "8A7BFF")
        static let accentLime = Color(hex: "B8FF5A")
        static let warning = Color(hex: "FFB347")
        static let danger = Color(hex: "FF5C7A")
        static let success = Color(hex: "5CFFB1")
        static let border = accentCyan.opacity(0.22)
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let safeHorizontal: CGFloat = 16
    }

    enum Radius {
        static let card: CGFloat = 16
        static let chip: CGFloat = 12
        static let button: CGFloat = 14
        static let tabBar: CGFloat = 34
    }

    enum Typography {
        static let hero = Font.system(size: 30, weight: .bold, design: .rounded)
        static let title = Font.system(size: 24, weight: .bold, design: .rounded)
        static let section = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let bodyStrong = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
        static let mono = Font.system(size: 15, weight: .regular, design: .monospaced)
    }

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.8)
    }
}

struct CyberpunkBackgroundV2: View {
    var body: some View {
        ZStack {
            DesignTokensV2.Colors.bg900

            RadialGradient(
                colors: [
                    DesignTokensV2.Colors.accentCyan.opacity(0.16),
                    .clear
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 360
            )

            RadialGradient(
                colors: [
                    DesignTokensV2.Colors.accentMagenta.opacity(0.1),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 420
            )

            LinearGradient(
                colors: [
                    DesignTokensV2.Colors.bg900,
                    DesignTokensV2.Colors.bg800
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.9)
        }
        .ignoresSafeArea()
    }
}
