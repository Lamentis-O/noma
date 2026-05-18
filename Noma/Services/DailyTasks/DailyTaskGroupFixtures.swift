import Foundation

enum DailyTaskGroupFixtures {
    static func state(calendar: Calendar = .current) -> DailyTaskGroupState {
        let projects = [
            TaskProject(title: "Work", symbolName: "terminal", colorIndex: 5),
            TaskProject(title: "Personal", symbolName: "heart", colorIndex: 1),
            TaskProject(title: "Home", symbolName: "wrench", colorIndex: 3)
        ]
        let today = calendar.startOfDay(for: Date())
        let groups = [
            group(daysFromToday: 0, reminders: [
                CreateReminder(text: "Review Noma task flow", projectID: projects[0].id),
                CreateReminder(text: "Plan dinner", projectID: projects[1].id)
            ], calendar: calendar, today: today),
            group(daysFromToday: -1, reminders: [
                CreateReminder(text: "Send project update", projectID: projects[0].id),
                CreateReminder(text: "Buy groceries", projectID: projects[2].id),
                CreateReminder(text: "Call back Alex", isCompleted: true, projectID: projects[1].id)
            ], calendar: calendar, today: today),
            group(daysFromToday: -2, reminders: [
                CreateReminder(text: "Draft sprint notes", isCompleted: true, projectID: projects[0].id),
                CreateReminder(text: "Clean kitchen", projectID: projects[2].id)
            ], calendar: calendar, today: today)
        ]

        return DailyTaskGroupState(groups: groups, projects: projects, selectedProjectID: nil)
    }

    private static func group(
        daysFromToday: Int,
        reminders: [CreateReminder],
        calendar: Calendar,
        today: Date
    ) -> DailyTaskGroup {
        let date = calendar.date(byAdding: .day, value: daysFromToday, to: today) ?? today
        return DailyTaskGroup(
            id: DailyTaskGroupStore.dayID(for: date, calendar: calendar),
            date: date,
            reminders: reminders
        )
    }
}
