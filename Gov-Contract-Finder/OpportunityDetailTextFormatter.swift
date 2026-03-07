import Foundation

enum OpportunityDetailTextFormatter {
    static func descriptionDisplayText(from rawText: String) -> String {
        let normalized = normalizeDescription(decodeHTMLEntities(stripHTML(rawText)))
        return wrapUnsafeTokens(normalized)
    }

    static func wrapUnsafeTokens(_ text: String) -> String {
        let softBreak = "\u{200B}"
        let separators = CharacterSet(charactersIn: "/-?&=:")

        var output = String()
        var runLength = 0

        for scalar in text.unicodeScalars {
            output.unicodeScalars.append(scalar)

            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                runLength = 0
                continue
            }

            if separators.contains(scalar) {
                output.append(softBreak)
                runLength = 0
                continue
            }

            runLength += 1
            if runLength >= 24 {
                output.append(softBreak)
                runLength = 0
            }
        }

        return output
    }

    private static func stripHTML(_ input: String) -> String {
        input.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    private static func decodeHTMLEntities(_ input: String) -> String {
        var output = input
        let replacements: [(String, String)] = [
            ("&nbsp;", " "),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'")
        ]

        for (entity, replacement) in replacements {
            output = output.replacingOccurrences(of: entity, with: replacement)
        }

        return output
    }

    private static func normalizeDescription(_ text: String) -> String {
        guard let data = text.data(using: .utf8) else { return text }
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return text }
        let values = extractValues(from: json)
        if values.isEmpty { return text }
        return values.joined(separator: "\n")
    }

    private static func extractValues(from json: Any) -> [String] {
        if let dict = json as? [String: Any] {
            return dict.keys.sorted().flatMap { extractValues(from: dict[$0] as Any) }
        }

        if let array = json as? [Any] {
            return array.flatMap { extractValues(from: $0) }
        }

        if let string = json as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]
        }

        if let number = json as? NSNumber {
            return [number.stringValue]
        }

        return []
    }
}
