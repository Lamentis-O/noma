@testable import Noma
import XCTest

final class DailyTaskNotificationTests: XCTestCase {
    func testScheduleUsesMorningAndEveningReminderTimes() {
        XCTAssertEqual(DailyTaskNotificationSchedule.morningComponents.hour, 9)
        XCTAssertEqual(DailyTaskNotificationSchedule.morningComponents.minute, 0)
        XCTAssertEqual(DailyTaskNotificationSchedule.eveningComponents.hour, 21)
        XCTAssertEqual(DailyTaskNotificationSchedule.eveningComponents.minute, 0)
    }

    func testRequestsIncludePlanningAndOpenTaskReminders() {
        let requests = DailyTaskNotificationRequestFactory.requests(
            reminders: [
                CreateReminder(text: "Plan launch"),
                CreateReminder(text: "Done", isCompleted: true)
            ]
        )

        XCTAssertEqual(requests.map(\.identifier), [
            DailyTaskNotificationIdentifier.morningPlanning,
            DailyTaskNotificationIdentifier.eveningOpenTasks
        ])
    }

    func testRequestsSkipEveningReminderWithoutOpenTasks() {
        let requests = DailyTaskNotificationRequestFactory.requests(
            reminders: [
                CreateReminder(text: "Done", isCompleted: true)
            ]
        )

        XCTAssertEqual(requests.map(\.identifier), [
            DailyTaskNotificationIdentifier.morningPlanning
        ])
    }
}
