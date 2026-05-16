import Foundation

struct DailyTaskMetrics: Equatable {
    static let defaultTodayTargetCount = 2

    let todayCompletedCount: Int
    let todayTargetCount: Int
    let streakCount: Int

    static func make(
        groups: [DailyTaskGroup],
        today: Date = Date(),
        calendar: Calendar = .current,
        todayTargetCount: Int = defaultTodayTargetCount
    ) -> DailyTaskMetrics {
        let groupsByID = groups.reduce(into: [String: DailyTaskGroup]()) { partialResult, group in
            partialResult[group.id] = group
        }
        let todayID = DailyTaskGroupStore.dayID(for: today, calendar: calendar)
        let todayCompletedCount = groupsByID[todayID]?.reminders.filter(\.isCompleted).count ?? 0

        return DailyTaskMetrics(
            todayCompletedCount: todayCompletedCount,
            todayTargetCount: todayTargetCount,
            streakCount: consecutiveTaskCreationDays(
                groupsByID: groupsByID,
                today: today,
                calendar: calendar
            )
        )
    }

    private static func consecutiveTaskCreationDays(
        groupsByID: [String: DailyTaskGroup],
        today: Date,
        calendar: Calendar
    ) -> Int {
        var streakCount = 0
        var date = today

        while true {
            let dayID = DailyTaskGroupStore.dayID(for: date, calendar: calendar)
            guard let group = groupsByID[dayID], group.taskCount > 0 else {
                return streakCount
            }

            streakCount += 1

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                return streakCount
            }

            date = previousDay
        }
    }
}
