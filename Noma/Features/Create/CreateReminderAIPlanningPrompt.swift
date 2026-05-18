import Foundation

extension CreateReminderAIPlanning {
    static func prompt(
        currentReminders: [CreateReminder],
        carryForwardReminders: [CreateReminder],
        projects: [TaskProject],
        localeIdentifier: String
    ) -> String {
        let context = AIPlanningPromptContext(
            localeIdentifier: localeIdentifier,
            currentReminders: currentReminders,
            carryForwardReminders: carryForwardReminders,
            projects: projects
        )
        let encodedContext = (try? JSONEncoder().encode(context))
            .flatMap { String(data: $0, encoding: .utf8) } ?? #"{"currentReminders":[],"carryForwardReminders":[],"projects":[]}"#

        return """
        Task organization context JSON:
        \(encodedContext)

        Return one JSON object only with this schema:
        {"taskOrganization":[{"id":"existing reminder id","priorityRank":1,"category":"short internal category"}],"carryForwardReminderIDs":["existing yesterday reminder id"]}
        Include every current reminder in taskOrganization when possible. Use priorityRank 1 for the most important task, then 2, 3, and so on.
        Use category only as internal organization metadata; keep it short and stable, such as work, personal, errands, admin, health, home, finance, or focus.
        Use carryForwardReminderIDs only for yesterday tasks worth adding to today. Use empty arrays when none clearly fit.
        """
    }
}

private struct AIPlanningPromptContext: Encodable {
    let localeIdentifier: String
    let currentReminders: [Reminder]
    let carryForwardReminders: [Reminder]
    let projects: [Project]

    init(
        localeIdentifier: String,
        currentReminders: [CreateReminder],
        carryForwardReminders: [CreateReminder],
        projects: [TaskProject]
    ) {
        self.localeIdentifier = localeIdentifier
        self.currentReminders = currentReminders.map(Reminder.init(reminder:))
        self.carryForwardReminders = carryForwardReminders.map(Reminder.init(reminder:))
        self.projects = projects.map(Project.init(project:))
    }

    struct Reminder: Encodable {
        let id: String
        let text: String
        let isCompleted: Bool
        let projectID: String?

        init(reminder: CreateReminder) {
            self.id = reminder.id.uuidString
            self.text = reminder.text
            self.isCompleted = reminder.isCompleted
            self.projectID = reminder.projectID?.uuidString
        }
    }

    struct Project: Encodable {
        let id: String
        let title: String

        init(project: TaskProject) {
            self.id = project.id.uuidString
            self.title = project.title
        }
    }
}
