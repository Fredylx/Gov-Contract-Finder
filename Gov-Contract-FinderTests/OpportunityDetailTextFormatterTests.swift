import Testing
@testable import Gov_Contract_Finder

struct OpportunityDetailTextFormatterTests {
    @Test func wrapUnsafeTokensAddsSoftBreaksForURLPunctuation() {
        let input = "https://prod.nais.nasa.gov/pub/pub_library"
        let output = OpportunityDetailTextFormatter.wrapUnsafeTokens(input)

        #expect(output.contains("\u{200B}"))
        #expect(output.contains("https:"))
        #expect(output.contains("prod."))
        #expect(output.contains("pub_library"))
    }

    @Test func wrapUnsafeTokensKeepsNormalSentenceReadable() {
        let input = "Agencies may submit capabilities and qualifications."
        let output = OpportunityDetailTextFormatter.wrapUnsafeTokens(input)

        #expect(output == input)
    }

    @Test func descriptionDisplayTextNormalizesAndWrapsJSONValues() {
        let input = """
        {"description":"https://example.com/some/really/long/path/that/should/wrap"}
        """
        let output = OpportunityDetailTextFormatter.descriptionDisplayText(from: input)

        #expect(!output.contains("{"))
        #expect(!output.contains("description"))
        #expect(output.contains("https"))
        #expect(output.contains("\u{200B}"))
    }
}
