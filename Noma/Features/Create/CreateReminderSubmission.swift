import Foundation
import SwiftUI

enum CreateReminderPriority: String, Codable, Equatable {
    case high
}

enum CreateReminderTiming: String, Codable, Equatable {
    case today
    case tomorrow
}

struct CreateReminder: Codable, Equatable, Identifiable {
    let id: UUID
    let text: String
    let isCompleted: Bool
    let projectID: TaskProject.ID?
    let priority: CreateReminderPriority?
    let timing: CreateReminderTiming?
    let timeText: String?

    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        projectID: TaskProject.ID? = nil,
        priority: CreateReminderPriority? = nil,
        timing: CreateReminderTiming? = nil,
        timeText: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.projectID = projectID
        self.priority = priority
        self.timing = timing
        self.timeText = timeText
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case isCompleted
        case projectID
        case priority
        case timing
        case timeText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        projectID = try container.decodeIfPresent(TaskProject.ID.self, forKey: .projectID)
        priority = try container.decodeIfPresent(CreateReminderPriority.self, forKey: .priority)
        timing = try container.decodeIfPresent(CreateReminderTiming.self, forKey: .timing)
        timeText = try container.decodeIfPresent(String.self, forKey: .timeText)
    }

    func togglingCompletion() -> CreateReminder {
        CreateReminder(
            id: id,
            text: text,
            isCompleted: !isCompleted,
            projectID: projectID,
            priority: priority,
            timing: timing,
            timeText: timeText
        )
    }
}

struct CreateReminderSubmissionResult: Equatable {
    let reminder: CreateReminder
    let remainingText: String
}

struct CreateReminderCaptureIntent: Equatable {
    let normalizedText: String
    let projectID: TaskProject.ID?
    let priority: CreateReminderPriority?
    let timing: CreateReminderTiming?
    let timeText: String?

    init(
        normalizedText: String,
        projectID: TaskProject.ID?,
        priority: CreateReminderPriority? = nil,
        timing: CreateReminderTiming? = nil,
        timeText: String? = nil
    ) {
        self.normalizedText = normalizedText
        self.projectID = projectID
        self.priority = priority
        self.timing = timing
        self.timeText = timeText
    }
}

enum CreateReminderCaptureIntelligence {
    static func intent(
        from text: String,
        projects: [TaskProject],
        tier: SubscriptionTier = .free
    ) -> CreateReminderCaptureIntent {
        let normalizedText = CreateReminderSubmission.normalizedText(from: text)
        guard !normalizedText.isEmpty else {
            return CreateReminderCaptureIntent(normalizedText: "", projectID: nil)
        }

        var intent = CreateReminderCaptureIntent(normalizedText: normalizedText, projectID: nil)
        if let explicitProject = explicitProject(in: normalizedText, projects: projects) {
            intent = explicitProject
        }

        guard tier.usesSmartCaptureIntelligence else { return intent }
        return CreateReminderSmartCaptureIntelligence.intent(from: intent)
    }

    private static func explicitProject(
        in normalizedText: String,
        projects: [TaskProject]
    ) -> CreateReminderCaptureIntent? {
        for project in projects {
            if let intent = hashIntent(for: project, in: normalizedText) {
                return intent
            }
            if let intent = bracketIntent(for: project, in: normalizedText) {
                return intent
            }
            if let intent = prefixIntent(for: project, in: normalizedText) {
                return intent
            }
        }
        return nil
    }

    private static func hashIntent(
        for project: TaskProject,
        in normalizedText: String
    ) -> CreateReminderCaptureIntent? {
        let marker = "#\(markerTitle(for: project))"
        guard let markerRange = normalizedText.range(
            of: marker,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) else { return nil }
        let cleanedText = normalizedText.replacingCharacters(in: markerRange, with: "")

        return cleanedIntent(cleanedText: cleanedText, projectID: project.id)
    }

    private static func bracketIntent(
        for project: TaskProject,
        in normalizedText: String
    ) -> CreateReminderCaptureIntent? {
        anchoredIntent(marker: "[\(project.title)]", projectID: project.id, in: normalizedText)
    }

    private static func prefixIntent(
        for project: TaskProject,
        in normalizedText: String
    ) -> CreateReminderCaptureIntent? {
        anchoredIntent(marker: "\(project.title):", projectID: project.id, in: normalizedText)
    }

    private static func anchoredIntent(
        marker: String,
        projectID: TaskProject.ID,
        in normalizedText: String
    ) -> CreateReminderCaptureIntent? {
        guard let markerRange = normalizedText.range(
            of: marker,
            options: [.anchored, .caseInsensitive, .diacriticInsensitive]
        ) else { return nil }
        let cleanedText = String(normalizedText[markerRange.upperBound...])

        return cleanedIntent(cleanedText: cleanedText, projectID: projectID)
    }

    private static func cleanedIntent(
        cleanedText: String,
        projectID: TaskProject.ID
    ) -> CreateReminderCaptureIntent? {
        let normalizedText = CreateReminderSubmission.normalizedText(from: cleanedText)
        guard !normalizedText.isEmpty else { return nil }

        return CreateReminderCaptureIntent(normalizedText: normalizedText, projectID: projectID)
    }

    private static func markerTitle(for project: TaskProject) -> String {
        project.title
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined()
    }
}

enum CreateReminderSmartCaptureIntelligence {
    static func intent(
        from intent: CreateReminderCaptureIntent
    ) -> CreateReminderCaptureIntent {
        let priority = detectedPriority(in: intent.normalizedText)
        let timing = detectedTiming(in: intent.normalizedText)
        let timeText = detectedTimeText(in: intent.normalizedText)
        let cleanedText = cleanSmartCaptureText(intent.normalizedText)

        return CreateReminderCaptureIntent(
            normalizedText: cleanedText,
            projectID: intent.projectID,
            priority: priority,
            timing: timing,
            timeText: timeText
        )
    }

    private static func detectedPriority(in text: String) -> CreateReminderPriority? {
        containsRegex(priorityPattern, in: text) ? .high : nil
    }

    private static func detectedTiming(in text: String) -> CreateReminderTiming? {
        if containsRegex(tomorrowPattern, in: text) {
            return .tomorrow
        }
        if containsRegex(todayPattern, in: text) {
            return .today
        }
        return nil
    }

    private static func detectedTimeText(in text: String) -> String? {
        guard let range = text.range(of: timePattern, options: .regularExpression) else { return nil }
        return CreateReminderSubmission.normalizedText(from: String(text[range]))
    }

    private static func cleanSmartCaptureText(_ text: String) -> String {
        [tomorrowPattern, todayPattern, priorityPattern, timePattern].reduce(text) { currentText, pattern in
            currentText.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        .components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    private static func containsRegex(_ pattern: String, in text: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    private static let todayPattern = #"(?i)(^|\s)(today|heute)(?=\s|$)"#
    private static let tomorrowPattern = #"(?i)(^|\s)(tomorrow|morgen)(?=\s|$)"#
    private static let priorityPattern = #"(?i)(^|\s)(!+|urgent|wichtig|prio|priority)(?=\s|$)"#
    private static let timePattern = #"(?i)(^|\s)(\d{1,2}:\d{2}|\d{1,2}\s*(uhr|am|pm))(?=\s|$)"#
}

enum CreateReminderSubmission {
    static let characterLimit = 1000

    static func normalizedText(from text: String) -> String {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    static func reminder(
        from text: String,
        id: UUID = UUID(),
        projectID: TaskProject.ID? = nil,
        priority: CreateReminderPriority? = nil,
        timing: CreateReminderTiming? = nil,
        timeText: String? = nil
    ) -> CreateReminder? {
        let normalizedText = normalizedText(from: text)
        guard !normalizedText.isEmpty, normalizedText.count <= characterLimit else { return nil }
        return CreateReminder(
            id: id,
            text: normalizedText,
            projectID: projectID,
            priority: priority,
            timing: timing,
            timeText: timeText
        )
    }

    static func submit(
        text: String,
        id: UUID = UUID(),
        projectID: TaskProject.ID? = nil
    ) -> CreateReminderSubmissionResult? {
        guard let reminder = reminder(from: text, id: id, projectID: projectID) else { return nil }
        return CreateReminderSubmissionResult(reminder: reminder, remainingText: "")
    }

    static func submit(
        text: String,
        id: UUID = UUID(),
        projects: [TaskProject],
        selectedProjectID: TaskProject.ID? = nil,
        tier: SubscriptionTier = .free
    ) -> CreateReminderSubmissionResult? {
        let intent = CreateReminderCaptureIntelligence.intent(from: text, projects: projects, tier: tier)
        let projectID = intent.projectID ?? selectedProjectID
        guard let reminder = reminder(
            from: intent.normalizedText,
            id: id,
            projectID: projectID,
            priority: intent.priority,
            timing: intent.timing,
            timeText: intent.timeText
        ) else { return nil }

        return CreateReminderSubmissionResult(reminder: reminder, remainingText: "")
    }
}

enum CreateReminderCompletionFeedback {
    static func feedback(isCompleted: Bool) -> HapticFeedbackClass? {
        isCompleted ? .createTaskSubmit : nil
    }
}

enum CreateReminderListFilter {
    static func visibleReminders(
        _ reminders: [CreateReminder],
        showsOnlyUnsolved: Bool
    ) -> [CreateReminder] {
        guard showsOnlyUnsolved else { return reminders }
        return reminders.filter { !$0.isCompleted }
    }
}

enum CreateReminderBatchCompletion {
    static func completingAll(_ reminders: [CreateReminder]) -> [CreateReminder] {
        reminders.map { reminder in
            reminder.isCompleted ? reminder : reminder.togglingCompletion()
        }
    }
}

enum CreateReminderFilterToolbarIcon {
    static func systemImage(isActive _: Bool) -> String {
        "line.3.horizontal.decrease"
    }

    static func usesActiveTint(isActive: Bool) -> Bool {
        isActive
    }

    static func foregroundColor(isActive: Bool) -> Color {
        usesActiveTint(isActive: isActive) ? .accentColor : .textPrimary
    }
}
