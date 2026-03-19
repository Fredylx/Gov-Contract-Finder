import Foundation
import Observation
import SwiftUI

enum FirstRunDemoStep: String, Codable {
    case intro
    case searchField
    case searchCTA
    case resultCard
    case completed
    case skipped

    var isFinished: Bool {
        switch self {
        case .completed, .skipped:
            return true
        case .intro, .searchField, .searchCTA, .resultCard:
            return false
        }
    }

    var isLiveStep: Bool {
        switch self {
        case .searchField, .searchCTA, .resultCard:
            return true
        case .intro, .completed, .skipped:
            return false
        }
    }

    var title: String {
        switch self {
        case .searchField:
            return "Search Keywords"
        case .searchCTA:
            return "Run Search"
        case .resultCard:
            return "Review Result"
        case .intro, .completed, .skipped:
            return ""
        }
    }

    var message: String {
        switch self {
        case .searchField:
            return "Start here. Enter a keyword like software to narrow opportunities."
        case .searchCTA:
            return "Tap Search to pull matching opportunities."
        case .resultCard:
            return "This is a result card. Open cards like this to review an opportunity."
        case .intro, .completed, .skipped:
            return ""
        }
    }
}

enum FirstRunDemoTarget: Hashable {
    case searchField
    case searchCTA
    case resultCard
}

enum FirstRunDemoCoordinateSpace {
    static let name = "FirstRunDemoCoordinateSpace"
}

@MainActor
@Observable
final class FirstRunDemoController {
    static let demoKeyword = "software"

    private let defaults: UserDefaults
    private let storageKey = "firstRunDemo.v2.step"

    var step: FirstRunDemoStep {
        didSet {
            guard step != oldValue else { return }
            defaults.set(step.rawValue, forKey: storageKey)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if
            let rawValue = defaults.string(forKey: storageKey),
            let persistedStep = FirstRunDemoStep(rawValue: rawValue)
        {
            step = persistedStep
        } else {
            step = .intro
            defaults.set(FirstRunDemoStep.intro.rawValue, forKey: storageKey)
        }
    }

    var isActive: Bool {
        !step.isFinished
    }

    var isShowingIntro: Bool {
        step == .intro
    }

    var isShowingCoachMarks: Bool {
        step.isLiveStep
    }

    var activeTarget: FirstRunDemoTarget? {
        switch step {
        case .searchField:
            return .searchField
        case .searchCTA:
            return .searchCTA
        case .resultCard:
            return .resultCard
        case .intro, .completed, .skipped:
            return nil
        }
    }

    func startDemo() {
        step = .searchField
    }

    func advanceFromSearchField() {
        guard step == .searchField else { return }
        step = .searchCTA
    }

    func advanceFromSearchCTA() {
        guard step == .searchCTA else { return }
        step = .resultCard
    }

    func complete() {
        step = .completed
    }

    func skip() {
        step = .skipped
    }
}

struct FirstRunDemoTargetFramePreferenceKey: PreferenceKey {
    static var defaultValue: [FirstRunDemoTarget: CGRect] = [:]

    static func reduce(value: inout [FirstRunDemoTarget: CGRect], nextValue: () -> [FirstRunDemoTarget: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct FirstRunDemoTargetFrameModifier: ViewModifier {
    let target: FirstRunDemoTarget

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FirstRunDemoTargetFramePreferenceKey.self,
                    value: [target: proxy.frame(in: .named(FirstRunDemoCoordinateSpace.name))]
                )
            }
        )
    }
}

extension View {
    func firstRunDemoTarget(_ target: FirstRunDemoTarget) -> some View {
        modifier(FirstRunDemoTargetFrameModifier(target: target))
    }
}

struct FirstRunDemoIntroOverlay: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.l) {
                Spacer(minLength: DesignTokens.Spacing.xxl)

                FirstRunDemoPreviewCard()

                NeoCard {
                    Text("Find your first contract fast")
                        .font(DesignTokens.Typography.hero)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    BoundedBodyText(
                        value: "We’ll show you the three actions that matter in Discover.",
                        color: DesignTokens.Colors.textPrimary
                    )

                    NeonButton(title: "Start Demo", icon: "sparkles") {
                        onStart()
                    }
                }
                .frame(maxWidth: 480)

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.l)
            .padding(.vertical, DesignTokens.Spacing.xl)

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    onStart()
                }
        }
    }
}

struct FirstRunCoachMarksOverlay: View {
    let step: FirstRunDemoStep
    let targetFrame: CGRect?
    let onTargetTap: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let overlayFrame = proxy.frame(in: .local)
            let highlightFrame = paddedHighlightFrame

            ZStack(alignment: .topLeading) {
                if let highlightFrame {
                    FirstRunSpotlightMask(cutout: highlightFrame, radius: 24)
                        .fill(Color.black.opacity(0.8), style: FillStyle(eoFill: true))
                        .ignoresSafeArea()
                } else {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                }

                if let highlightFrame {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [DesignTokens.Colors.accentCyan, DesignTokens.Colors.accentViolet],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: highlightFrame.width, height: highlightFrame.height)
                        .position(x: highlightFrame.midX, y: highlightFrame.midY)
                        .shadow(color: DesignTokens.Colors.accentCyan.opacity(0.35), radius: 16)
                }

                if let highlightFrame {
                    FirstRunCoachMarkCard(title: step.title, message: step.message)
                        .frame(width: min(overlayFrame.width - (DesignTokens.Spacing.l * 2), 320))
                        .position(calloutPosition(in: overlayFrame, for: highlightFrame))
                }

                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        onTargetTap()
                    }
            }
        }
        .ignoresSafeArea()
    }

    private var paddedHighlightFrame: CGRect? {
        guard let targetFrame else { return nil }
        return targetFrame.insetBy(dx: -8, dy: -8)
    }

    private func calloutPosition(in overlayFrame: CGRect, for highlightFrame: CGRect) -> CGPoint {
        let horizontalPadding = DesignTokens.Spacing.l
        let bubbleWidth = min(overlayFrame.width - (horizontalPadding * 2), 320)
        let halfBubbleWidth = bubbleWidth / 2
        let clampedX = min(
            max(highlightFrame.midX, halfBubbleWidth + horizontalPadding),
            overlayFrame.maxX - halfBubbleWidth - horizontalPadding
        )
        let preferredY: CGFloat
        if step == .resultCard {
            preferredY = highlightFrame.midY + 90
        } else {
            let showAbove = highlightFrame.midY > overlayFrame.height * 0.58
            preferredY = showAbove ? highlightFrame.minY - 100 : highlightFrame.maxY + 100
        }
        let clampedY = min(max(preferredY, 120), overlayFrame.maxY - 140)
        return CGPoint(x: clampedX, y: clampedY)
    }
}

private struct FirstRunCoachMarkCard: View {
    let title: String
    let message: String

    var bodyView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.section)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            BoundedBodyText(value: message, color: DesignTokens.Colors.textPrimary)
        }
        .padding(DesignTokens.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .fill(DesignTokens.Colors.bg800.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .stroke(DesignTokens.Colors.accentCyan.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: DesignTokens.Colors.accentCyan.opacity(0.22), radius: 18)
    }

    var body: some View {
        bodyView
    }
}

private struct FirstRunDemoPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
            HStack {
                Text("Gov Contract Hunter")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.accentCyan)
                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Discover")
                    .font(DesignTokens.Typography.hero)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                BoundedBodyText(value: "Find federal opportunities for your team.")
            }

            VStack(spacing: DesignTokens.Spacing.s) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                    .fill(DesignTokens.Colors.surface2)
                    .frame(height: 46)
                    .overlay(alignment: .leading) {
                        Text("Search keywords...")
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .padding(.horizontal, DesignTokens.Spacing.m)
                    }

                RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Colors.accentCyan, DesignTokens.Colors.accentViolet],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 50)
                    .overlay {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "magnifyingglass")
                            Text("Search Opportunities")
                        }
                        .font(DesignTokens.Typography.bodyStrong)
                        .foregroundStyle(DesignTokens.Colors.bg900)
                    }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                Text("Cloud Migration Support Services")
                    .font(DesignTokens.Typography.section)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                BoundedBodyText(value: "Department of Energy")

                HStack(spacing: DesignTokens.Spacing.xs) {
                    Badge(text: "Posted 03/12/2026", color: DesignTokens.Colors.accentCyan)
                    Badge(text: "Viewed", color: DesignTokens.Colors.textSecondary)
                }
            }
            .padding(DesignTokens.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .fill(DesignTokens.Colors.surface.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
            )
        }
        .padding(DesignTokens.Spacing.l)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DesignTokens.Colors.bg900.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(DesignTokens.Colors.accentCyan.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: DesignTokens.Colors.accentCyan.opacity(0.18), radius: 18, y: 10)
    }
}

private struct FirstRunSpotlightMask: Shape {
    let cutout: CGRect
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRoundedRect(
            in: cutout,
            cornerSize: CGSize(width: radius, height: radius)
        )
        return path
    }
}

extension Opportunity {
    static let walkthroughDemo = Opportunity(
        id: "walkthrough-demo-opportunity",
        title: "Cloud Migration Support Services",
        agency: "Department of Energy",
        postedDate: "03/12/2026",
        description: "Support a multi-agency software modernization effort with cloud migration and security hardening services.",
        solicitationNumber: "DEMO-SEARCH-001",
        responseDate: "03/28/2026",
        setAsideCode: "SBA",
        naicsCode: "541519",
        naicsDescription: "Other Computer Related Services",
        contactEmail: "demo.contracting@example.gov",
        contactName: "Jordan Ellis",
        contactPhone: "555-0134",
        contacts: [
            Opportunity.Contact(
                id: "walkthrough-demo-contact",
                type: "primary",
                title: "Contracting Officer",
                fullName: "Jordan Ellis",
                email: "demo.contracting@example.gov",
                phone: "555-0134",
                fax: nil
            )
        ]
    )
}
