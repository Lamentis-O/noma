import SwiftUI

extension CreateView {
    var carryForwardReminders: [CreateReminder] {
        let currentReminderKeys = Set(reminders.map(CarryForwardReminderKey.init(reminder:)))

        return dailyTaskGroups
            .openRemindersFromPreviousDay(beforeDayID: dayID)
            .filter { !currentReminderKeys.contains(CarryForwardReminderKey(reminder: $0)) }
    }

    var showsCarryForwardButton: Bool {
        subscriptionTier.tier == .pro && !carryForwardReminders.isEmpty
    }

    var carryForwardButton: some View {
        Button(action: carryForwardOpenTasks) {
            HStack(spacing: NomaSpacing.sm) {
                Image(systemName: "text.line.3.summary")
                    .font(.headline)
                    .frame(width: ReminderInputBarLayout.minimumHeight)

                Text("create.carry-forward-yesterday.title")
                    .font(.headline)
            }
            .foregroundStyle(.textPrimary)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    func carryForwardOpenTasks() {
        let remindersToAdd = carryForwardReminders.map { reminder in
            CreateReminder(text: reminder.text, projectID: reminder.projectID)
        }
        guard !remindersToAdd.isEmpty else { return }

        hapticFeedback.play(.createTaskSubmit)
        withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
            reminders.append(contentsOf: remindersToAdd)
        }
        saveCurrentDailyGroup()
        pendingScrollTargetID = CreateReminderListLayout.bottomAnchorID
    }
}

private struct CarryForwardReminderKey: Hashable {
    let text: String
    let projectID: TaskProject.ID?

    init(reminder: CreateReminder) {
        self.text = reminder.text
        self.projectID = reminder.projectID
    }
}
