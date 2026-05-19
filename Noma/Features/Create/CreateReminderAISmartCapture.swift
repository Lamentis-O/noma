import Foundation

enum CreateReminderAISmartCapture {
    static func submit(
        text: String,
        id: UUID = UUID(),
        projects: [TaskProject],
        selectedProjectID: TaskProject.ID?,
        tier: SubscriptionTier,
        foundationModel: OnDeviceFoundationModelService
    ) async -> CreateReminderSubmissionResult? {
        let fallback = CreateReminderSubmission.submit(
            text: text,
            id: id,
            projects: projects,
            selectedProjectID: selectedProjectID
        )
        guard tier.canUseOnDeviceFoundationModels else { return fallback }

        let baseIntent = CreateReminderCaptureIntelligence.intent(from: text, projects: projects)
        guard !baseIntent.normalizedText.isEmpty else { return fallback }

        do {
            let response = try await foundationModel.generateResponse(
                prompt: prompt(for: baseIntent.normalizedText, projects: projects),
                instructions: instructions,
                tier: tier,
                maximumResponseTokens: 240
            )
            guard let suggestion = try SmartCaptureSuggestion.decode(from: response) else {
                return fallback
            }

            return submission(
                from: suggestion,
                fallback: fallback,
                id: id,
                baseIntent: baseIntent,
                projects: projects,
                selectedProjectID: selectedProjectID
            )
        } catch {
            return fallback
        }
    }

    private static func submission(
        from suggestion: SmartCaptureSuggestion,
        fallback: CreateReminderSubmissionResult?,
        id: UUID,
        baseIntent: CreateReminderCaptureIntent,
        projects: [TaskProject],
        selectedProjectID: TaskProject.ID?
    ) -> CreateReminderSubmissionResult? {
        let normalizedTitle = CreateReminderSubmission.normalizedText(from: suggestion.title)
        guard !normalizedTitle.isEmpty, normalizedTitle.count <= CreateReminderSubmission.characterLimit else {
            return fallback
        }

        let projectID = baseIntent.projectID
            ?? projectID(for: suggestion, projects: projects)
            ?? selectedProjectID
        guard let reminder = CreateReminderSubmission.reminder(from: normalizedTitle, id: id, projectID: projectID) else {
            return fallback
        }

        return CreateReminderSubmissionResult(reminder: reminder, remainingText: "")
    }

    private static func projectID(
        for suggestion: SmartCaptureSuggestion,
        projects: [TaskProject]
    ) -> TaskProject.ID? {
        if let suggestedProjectID = suggestion.projectID,
           let uuid = UUID(uuidString: suggestedProjectID),
           let project = projects.first(where: { $0.id == uuid }) {
            return project.id
        }

        if let suggestedProjectTitle = suggestion.projectTitle {
            return projects.first {
                $0.title.compare(
                    suggestedProjectTitle,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) == .orderedSame
            }?.id
        }

        return nil
    }

    private static let instructions = """
    You are Noma's private on-device task capture model.
    Extract a concise task title and optionally choose the best existing project.
    Never invent projects. Never return markdown, explanations, arrays, or extra keys.
    Preserve useful dates, times, names, and priority words inside the title because the app stores one task text field.
    """
}
