import Foundation

struct Reminder: Codable, Identifiable {
    let id: UUID
    let title: String
    let dueDate: Date
    let createdAt: Date
    let transcript: String

    init(id: UUID = UUID(), title: String, dueDate: Date, createdAt: Date = Date(), transcript: String) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.transcript = transcript
    }
}
