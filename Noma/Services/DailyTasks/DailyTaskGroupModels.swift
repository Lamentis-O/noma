import Foundation

struct DailyTaskGroup: Codable, Equatable, Identifiable {
    let id: String
    let date: Date
    var reminders: [CreateReminder]

    var taskCount: Int { reminders.count }
}

struct DailyTaskGroupSummary: Equatable, Identifiable {
    let group: DailyTaskGroup

    var id: String { group.id }
    var taskCount: Int { group.taskCount }
    var completedTaskCount: Int { group.reminders.filter(\.isCompleted).count }
    var isCompleted: Bool { taskCount > 0 && completedTaskCount == taskCount }
    var taskCountUnitKey: String {
        taskCount == 1 ? "home.daily-groups.task-count.singular" : "home.daily-groups.task-count.plural"
    }

    var title: String {
        group.date.formatted(date: .abbreviated, time: .omitted)
    }
}

enum DailyTaskGroupsSection {
    static let headerTitleKey = "home.daily-groups.section-header"
}

enum DailyTaskGroupsProgressCopy {
    static let ofKey = "home.daily-groups.progress.of"
    static let doneKey = "home.daily-groups.progress.done"
}
