import XCTest
@testable import ZenReminder

final class ReminderIntentParserTests: XCTestCase {
    func testParsesRelativeReminder() throws {
        let parser = ReminderIntentParser()
        let intent = try parser.parse("Remind me to call Maya in 10 minutes")

        XCTAssertEqual(intent.reminder.title, "Call Maya")
        XCTAssertGreaterThan(intent.reminder.dueDate.timeIntervalSinceNow, 540)
        XCTAssertLessThan(intent.reminder.dueDate.timeIntervalSinceNow, 660)
    }

    func testRequiresDate() {
        let parser = ReminderIntentParser()

        XCTAssertThrowsError(try parser.parse("Remind me to check the oven")) { error in
            XCTAssertTrue(error is ReminderIntentParserError)
        }
    }
}
