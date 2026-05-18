import SwiftUI

extension CreateView {
    var showsAIPlanningButton: Bool {
        subscriptionTier.tier.canUseOnDeviceFoundationModels
            && CreateReminderSubmission.normalizedText(from: message).isEmpty
            && !isPlanningDay
            && dailyPlan == nil
            && (!reminders.isEmpty || !carryForwardReminders.isEmpty)
    }

    var aiPlanningButton: some View {
        CreateComposerSuggestionButton(
            systemImage: "sparkles",
            titleKey: "create.ai-plan.button.title",
            action: generateDailyPlan
        )
    }

    func carryForwardOpenTasks() {
        guard !isPlanningDay else { return }
        addCarryForwardReminders(dailyPlan.map(carryForwardReminders(for:)) ?? carryForwardReminders)
    }

    func generateDailyPlan() {
        generateDailyPlan(afterPlanning: { _ in })
    }

    private func generateDailyPlan(afterPlanning: @escaping (CreateReminderAIPlanningResult?) -> Void) {
        guard !isPlanningDay else { return }

        isPlanningDay = true
        Task {
            let plan = await CreateReminderAIPlanning.plan(
                currentReminders: reminders,
                carryForwardReminders: carryForwardReminders,
                projects: projects,
                tier: subscriptionTier.tier,
                foundationModel: onDeviceFoundationModel
            )

            await MainActor.run {
                withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
                    isPlanningDay = false
                    dailyPlan = plan
                }
                afterPlanning(plan)
            }
        }
    }

    func carryForwardReminders(for plan: CreateReminderAIPlanningResult) -> [CreateReminder] {
        let recommendedIDs = Set(plan.carryForwardReminderIDs)
        return carryForwardReminders.filter { recommendedIDs.contains($0.id) }
    }
}

private struct CreateComposerSuggestionButton: View {
    let systemImage: String
    let titleKey: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: NomaSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .frame(width: ReminderInputBarLayout.minimumHeight)

                Text(titleKey)
                    .font(.headline)
            }
            .foregroundStyle(.textPrimary)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
