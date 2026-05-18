import Foundation

extension CreateReminderAISmartCapture {
    static func prompt(for text: String, projects: [TaskProject]) -> String {
        let projectContext = SmartCaptureProjectContext(projects: projects)
        let encodedProjects = (try? JSONEncoder().encode(projectContext))
            .flatMap { String(data: $0, encoding: .utf8) } ?? #"{"projects":[]}"#

        return """
        User task input:
        \(text)

        Available projects JSON:
        \(encodedProjects)

        Return one JSON object only with this schema:
        {"title":"clean task title preserving useful date/time words","projectID":"matching project id or null","projectTitle":"matching project title or null"}
        Use only the provided project ids and titles. Use null for project fields when no project clearly matches.
        """
    }
}

private struct SmartCaptureProjectContext: Encodable {
    let projects: [Project]

    init(projects: [TaskProject]) {
        self.projects = projects.map { Project(id: $0.id.uuidString, title: $0.title) }
    }

    struct Project: Encodable {
        let id: String
        let title: String
    }
}
