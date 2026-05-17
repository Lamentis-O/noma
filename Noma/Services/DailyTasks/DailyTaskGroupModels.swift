import Foundation

struct DailyTaskGroup: Codable, Equatable, Identifiable {
    let id: String
    let date: Date
    var reminders: [CreateReminder]
    var projects: [TaskProject]
    var selectedProjectID: TaskProject.ID?

    init(
        id: String,
        date: Date,
        reminders: [CreateReminder],
        projects: [TaskProject] = [],
        selectedProjectID: TaskProject.ID? = nil
    ) {
        self.id = id
        self.date = date
        self.reminders = reminders
        self.projects = projects
        self.selectedProjectID = selectedProjectID
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case reminders
        case projects
        case selectedProjectID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        reminders = try container.decode([CreateReminder].self, forKey: .reminders)
        projects = try container.decodeIfPresent([TaskProject].self, forKey: .projects) ?? []
        selectedProjectID = try container.decodeIfPresent(TaskProject.ID.self, forKey: .selectedProjectID)
    }

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
    static let completedKey = "home.daily-groups.progress.completed"
}
