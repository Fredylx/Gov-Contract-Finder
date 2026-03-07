import SwiftUI

@main
struct GovContractFinderApp: App {
    private let uiTestDetailLaunchArg = "-uiTest-openDetailFixture"
    private let uiTestEnableV2Arg = "-uiTest-enableV2"

    var body: some Scene {
        WindowGroup {
            let arguments = ProcessInfo.processInfo.arguments
            let _ = configureFeatureFlagsIfNeeded(arguments: arguments)

            if arguments.contains(uiTestDetailLaunchArg) {
                NavigationStack {
                    OpportunityDetailView(opportunity: .uiTestDetailFixture)
                        .accessibilityIdentifier("opportunity_detail_screen")
                }
            } else {
                RootView()
            }
        }
    }

    private func configureFeatureFlagsIfNeeded(arguments: [String]) {
        if arguments.contains(uiTestEnableV2Arg) {
            FeatureFlags.shared.v2ShellEnabled = true
        }
    }
}

private extension Opportunity {
    static let uiTestDetailFixture = Opportunity(
        id: "ui-test-opportunity-1",
        title: "UI Test Opportunity",
        agency: "Department of Test Coverage",
        postedDate: "03/01/2026",
        description: """
        This is a deterministic long description used by UI tests to validate that text wraps inside the phone viewport and never overflows horizontally.

        Organizations may submit their capabilities and qualifications in writing to the identified point of contact not later than 12 PM PT on 03/04/2026.

        Reference link for stress testing wrap behavior:
        http://prod.nais.nasa.gov/pub/pub_library/this_is_a_very_long_unbroken_segment_that_should_wrap_at_safe_edges_without_horizontal_clipping_or_sideways_scroll
        """,
        solicitationNumber: "UITEST-12345",
        fullParentPathName: "Test Agency/Space Systems/Long Form Procurement Division",
        fullParentPathCode: "TA/SS/LFPD",
        office: "Office of Acquisition and Lifecycle Management",
        uiLink: "https://sam.gov",
        additionalInfoLink: "https://example.com/additional-info",
        resourceLinks: [
            "https://example.com/attachments/this-is-an-intentionally-long-attachment-name-to-validate-line-wrap.pdf"
        ],
        responseDate: "03/20/2026",
        setAsideCode: "SBA",
        naicsCode: "541519",
        naicsDescription: "Other Computer Related Services",
        contactEmail: "ui.test@example.com",
        contactName: "Test Contact",
        contactPhone: "555-0100",
        contacts: [
            Opportunity.Contact(
                id: "ui-test-contact-1",
                type: "primary",
                title: "Contracting Officer",
                fullName: "Jordan Test",
                email: "jordan.test@example.com",
                phone: "555-0100",
                fax: nil
            )
        ]
    )
}
