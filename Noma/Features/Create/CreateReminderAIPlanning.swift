import Foundation

struct CreateReminderAIPlanningResult: Equatable {
    let summary: String
    let focusReminderID: CreateReminder.ID?
    let carryForwardReminderIDs: [CreateReminder.ID]
    let deferredReminderIDs: [CreateReminder.ID]
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
                maximumResponseTokens: 320
            )
            guard let suggestion = try AIPlanningSuggestion.decode(from: response) else {
                return nil
            }

            return result(
                from: suggestion,
                currentReminders: currentReminders,
                carryForwardReminders: carryForwardReminders
            )
        } catch {
            return nil
        }
    }

    private static func result(
        from suggestion: AIPlanningSuggestion,
        currentReminders: [CreateReminder],
        carryForwardReminders: [CreateReminder]
    ) -> CreateReminderAIPlanningResult? {
        let summary = normalizedSummary(suggestion.summary)
        guard !summary.isEmpty else { return nil }

        let knownReminderIDs = Set((currentReminders + carryForwardReminders).map(\.id))
        let carryForwardIDs = validatedIDs(suggestion.carryForwardReminderIDs, allowedIDs: Set(carryForwardReminders.map(\.id)))
        let deferredIDs = validatedIDs(suggestion.deferredReminderIDs, allowedIDs: knownReminderIDs)
        let focusID = suggestion.focusReminderID
            .flatMap(UUID.init(uuidString:))
            .flatMap { knownReminderIDs.contains($0) ? $0 : nil }

        return CreateReminderAIPlanningResult(
            summary: summary,
            focusReminderID: focusID,
            carryForwardReminderIDs: carryForwardIDs,
            deferredReminderIDs: deferredIDs
        )
    }

    private static func normalizedSummary(_ text: String) -> String {
        let normalized = CreateReminderSubmission.normalizedText(from: text)
        guard normalized.count <= summaryCharacterLimit else {
            return String(normalized.prefix(summaryCharacterLimit)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return normalized
    }

    private static func validatedIDs(_ rawIDs: [String], allowedIDs: Set<UUID>) -> [UUID] {
        rawIDs
            .compactMap(UUID.init(uuidString:))
            .filter { allowedIDs.contains($0) }
            .uniqued()
    }

    private static let summaryCharacterLimit = 180

    private static let instructions = """
    You are Noma's private on-device daily planning model.
    Help the user choose a realistic plan for today using only the provided tasks and projects.
    Never invent tasks or projects. Never return markdown, explanations, or extra keys.
    Prefer a concise, calm, useful summary in the user's locale.
    """
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
