import Foundation

struct CreateReminder: Codable, Equatable, Identifiable {
    let id: UUID
    let text: String
    let isCompleted: Bool

    init(id: UUID = UUID(), text: String, isCompleted: Bool = false) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
    }

    func togglingCompletion() -> CreateReminder {
        CreateReminder(id: id, text: text, isCompleted: !isCompleted)
    }
}

struct CreateReminderSubmissionResult: Equatable {
    let reminder: CreateReminder
    let remainingText: String
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

    static func reminder(from text: String, id: UUID = UUID()) -> CreateReminder? {
        let normalizedText = normalizedText(from: text)
        guard !normalizedText.isEmpty, normalizedText.count <= characterLimit else { return nil }
        return CreateReminder(id: id, text: normalizedText)
    }

    static func submit(text: String, id: UUID = UUID()) -> CreateReminderSubmissionResult? {
        guard let reminder = reminder(from: text, id: id) else { return nil }
        return CreateReminderSubmissionResult(reminder: reminder, remainingText: "")
    }
}

enum CreateReminderCompletionFeedback {
    static func feedback(isCompleted: Bool) -> HapticFeedbackClass? {
        isCompleted ? .createTaskSubmit : nil
    }
}
