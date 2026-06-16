import Foundation

final class ReminderStore {
    private let fileManager = FileManager.default

    private var remindersURL: URL {
        get throws {
            let directory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("ZenReminder", isDirectory: true)

            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory.appendingPathComponent("reminders.json")
        }
    }

    func save(_ reminder: Reminder) throws {
        var reminders = try load()
        reminders.append(reminder)

        let data = try JSONEncoder.zen.encode(reminders)
        try data.write(to: try remindersURL, options: [.atomic])
    }

    func load() throws -> [Reminder] {
        let url = try remindersURL
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder.zen.decode([Reminder].self, from: data)
    }
}

private extension JSONEncoder {
    static var zen: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var zen: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
