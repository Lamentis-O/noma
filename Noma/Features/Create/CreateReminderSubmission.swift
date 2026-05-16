import Foundation

struct CreateReminder: Equatable, Identifiable {
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
    static func reminder(from text: String, id: UUID = UUID()) -> CreateReminder? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return nil }
        return CreateReminder(id: id, text: trimmedText)
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
