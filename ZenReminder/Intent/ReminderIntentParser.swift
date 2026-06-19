import Foundation

final class ReminderIntentParser {
    private let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

    func parse(_ transcript: String) throws -> ReminderIntent {
        let normalized = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw ReminderIntentParserError.emptyTranscript
        }

        let dateRange = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        let match = detector?.firstMatch(in: normalized, options: [], range: dateRange)
        let dueDate = match?.date ?? parseRelativeDate(in: normalized)

        guard let dueDate else {
            throw ReminderIntentParserError.missingDate
        }

        var title = normalized
        if let matchRange = match?.range, let range = Range(matchRange, in: normalized) {
            title.removeSubrange(range)
        }

        title = cleanTitle(title)
        guard !title.isEmpty else {
            throw ReminderIntentParserError.missingTitle
        }

        return ReminderIntent(reminder: Reminder(title: title, dueDate: dueDate, transcript: transcript))
    }

    private func parseRelativeDate(in text: String) -> Date? {
        let lower = text.lowercased()
        let pattern = #"in\s+(\d+)\s+(minute|minutes|hour|hours|day|days)"#
        guard
            let expression = try? NSRegularExpression(pattern: pattern),
            let match = expression.firstMatch(in: lower, range: NSRange(lower.startIndex..<lower.endIndex, in: lower)),
            match.numberOfRanges == 3,
            let amountRange = Range(match.range(at: 1), in: lower),
            let unitRange = Range(match.range(at: 2), in: lower),
            let amount = Int(lower[amountRange])
        else {
            return nil
        }

        let unit = String(lower[unitRange])
        let seconds: TimeInterval
        if unit.hasPrefix("minute") {
            seconds = TimeInterval(amount * 60)
        } else if unit.hasPrefix("hour") {
            seconds = TimeInterval(amount * 60 * 60)
        } else {
            seconds = TimeInterval(amount * 24 * 60 * 60)
        }

        return Date().addingTimeInterval(seconds)
    }

    private func cleanTitle(_ title: String) -> String {
        var cleaned = title
        let removablePhrases = [
            "remind me to",
            "remind me about",
            "remind me",
            "set a reminder to",
            "set reminder to",
            "create a reminder to",
            "create reminder to"
        ]

        for phrase in removablePhrases {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: "", options: [.caseInsensitive])
        }

        cleaned = cleaned
            .replacingOccurrences(of: #"\bat\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bon\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bin\s+\d+\s+(minute|minutes|hour|hours|day|days)"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let first = cleaned.first else { return cleaned }
        return first.uppercased() + cleaned.dropFirst()
    }
}

struct ReminderIntent {
    let reminder: Reminder
}

enum ReminderIntentParserError: Error {
    case emptyTranscript
    case missingDate
    case missingTitle
}
