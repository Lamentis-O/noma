import Foundation

struct CreateReminderAIPlanningResult: Equatable {
    let organizedTasks: [CreateReminderAIOrganizedTask]
    let carryForwardReminderIDs: [CreateReminder.ID]
}

struct CreateReminderAIOrganizedTask: Equatable {
    let reminderID: CreateReminder.ID
    let priorityRank: Int
    let category: String
}

enum CreateReminderAIPlanning {
    static func plan(
        currentReminders: [CreateReminder],
        carryForwardReminders: [CreateReminder],
        projects: [TaskProject],
        tier: SubscriptionTier,
        foundationModel: OnDeviceFoundationModelService,
        localeIdentifier: String = Locale.current.identifier
    ) async -> CreateReminderAIPlanningResult? {
        guard tier.canUseOnDeviceFoundationModels else { return nil }
        guard !currentReminders.isEmpty || !carryForwardReminders.isEmpty else { return nil }

        do {
            let response = try await foundationModel.generateResponse(
                prompt: prompt(
                    currentReminders: currentReminders,
                    carryForwardReminders: carryForwardReminders,
                    projects: projects,
                    localeIdentifier: localeIdentifier
                ),
                instructions: instructions,
                tier: tier,
                maximumResponseTokens: 420
            )
            guard let suggestion = try AIPlanningSuggestion.decode(from: response) else { return nil }
            return result(from: suggestion, currentReminders: currentReminders, carryForwardReminders: carryForwardReminders)
        } catch {
            return nil
        }
    }

    private static func result(
        from suggestion: AIPlanningSuggestion,
        currentReminders: [CreateReminder],
        carryForwardReminders: [CreateReminder]
    ) -> CreateReminderAIPlanningResult? {
        let knownReminderIDs = Set((currentReminders + carryForwardReminders).map(\.id))
        let carryForwardIDs = validatedIDs(suggestion.carryForwardReminderIDs, allowedIDs: Set(carryForwardReminders.map(\.id)))
        let organizedTasks = validatedOrganizedTasks(suggestion.taskOrganization, allowedIDs: knownReminderIDs)
        guard !organizedTasks.isEmpty || !carryForwardIDs.isEmpty else { return nil }

        return CreateReminderAIPlanningResult(organizedTasks: organizedTasks, carryForwardReminderIDs: carryForwardIDs)
    }

    private static func validatedIDs(_ rawIDs: [String], allowedIDs: Set<UUID>) -> [UUID] {
        rawIDs
            .compactMap(UUID.init(uuidString:))
            .filter { allowedIDs.contains($0) }
            .uniqued()
    }

    private static func validatedOrganizedTasks(
        _ rawTasks: [AIPlanningSuggestion.OrganizedTask],
        allowedIDs: Set<UUID>
    ) -> [CreateReminderAIOrganizedTask] {
        var seenIDs = Set<UUID>()
        return rawTasks.compactMap { rawTask in
            guard let reminderID = UUID(uuidString: rawTask.id),
                  allowedIDs.contains(reminderID),
                  seenIDs.insert(reminderID).inserted
            else { return nil }

            return CreateReminderAIOrganizedTask(reminderID: reminderID, priorityRank: max(1, rawTask.priorityRank), category: normalizedCategory(rawTask.category))
        }
    }

    private static func normalizedCategory(_ category: String) -> String {
        let normalized = CreateReminderSubmission.normalizedText(from: category)
        guard !normalized.isEmpty else { return defaultCategory }
        return String(normalized.prefix(categoryCharacterLimit))
    }

    private static let categoryCharacterLimit = 40
    private static let defaultCategory = "general"

    private static let instructions = """
    You are Noma's private on-device task organization model.
    Organize the user's existing tasks using only the provided task and project context.
    Never invent tasks or projects. Never return markdown, explanations, or extra keys.
    Prefer lower priorityRank values for tasks that are important, concrete, or time-sensitive.
    """
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
