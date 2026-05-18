import SwiftUI

extension CreateView {
    func carryForwardOpenTasks() {
        guard !isPlanningDay else { return }
        addCarryForwardReminders(
            CreateReminderCarryForwardAIRecommendation.reminders(
                from: carryForwardReminders,
                using: taskOrganization
            )
        )
    }

    func organizeTasksWithAIAfterUserAddedTask() {
        switch CreateReminderAIPlanningTrigger.actionAfterUserAddedTask(
            canUseOnDeviceFoundationModels: subscriptionTier.tier.canUseOnDeviceFoundationModels,
            isPlanningDay: isPlanningDay
        ) {
        case .skip:
            return
        case .scheduleAfterCurrentPlanning:
            shouldPlanAgainAfterCurrentPlanning = true
            return
        case .startNow:
            startAIPlanning()
        }
    }

    private func startAIPlanning() {
        let originatingDayID = activeDayID
        let currentReminders = reminders
        let currentCarryForwardReminders = carryForwardReminders
        let currentProjects = projects
        isPlanningDay = true
        Task {
            let plan = await CreateReminderAIPlanning.plan(
                currentReminders: currentReminders,
                carryForwardReminders: currentCarryForwardReminders,
                projects: currentProjects,
                tier: subscriptionTier.tier,
                foundationModel: onDeviceFoundationModel
            )

            await MainActor.run {
                guard CreateReminderAIPlanningResultAcceptance.acceptsResult(
                    originatingDayID: originatingDayID,
                    activeDayID: activeDayID
                ) else { return }
                withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
                    isPlanningDay = false
                    taskOrganization = plan
                }
                if shouldPlanAgainAfterCurrentPlanning {
                    shouldPlanAgainAfterCurrentPlanning = false
                    startAIPlanning()
                }
            }
        }
    }

}

enum CreateReminderAIPlanningTrigger {
    enum Action: Equatable {
        case skip
        case startNow
        case scheduleAfterCurrentPlanning
    }

    static func actionAfterUserAddedTask(
        canUseOnDeviceFoundationModels: Bool,
        isPlanningDay: Bool
    ) -> Action {
        guard canUseOnDeviceFoundationModels else { return .skip }
        return isPlanningDay ? .scheduleAfterCurrentPlanning : .startNow
    }
}

enum CreateReminderAIPlanningResultAcceptance {
    static func acceptsResult(originatingDayID: String, activeDayID: String) -> Bool {
        originatingDayID == activeDayID
    }
}

enum CreateReminderCarryForwardAIRecommendation {
    static func reminders(
        from carryForwardReminders: [CreateReminder],
        using plan: CreateReminderAIPlanningResult?
    ) -> [CreateReminder] {
        guard let plan, !plan.carryForwardReminderIDs.isEmpty else {
            return carryForwardReminders
        }

        let recommendedIDs = Set(plan.carryForwardReminderIDs)
        return carryForwardReminders.filter { recommendedIDs.contains($0.id) }
    }
}
