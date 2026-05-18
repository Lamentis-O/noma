import SwiftUI

extension CreateView {
    func loadDailyGroup() {
        reminders = dailyTaskGroups.reminders(forDayID: dayID)
        projects = dailyTaskGroups.projects(forDayID: dayID)

        let storedSelectedProjectID = dailyTaskGroups.selectedProjectID(forDayID: dayID)
        selectedProjectID = projects.contains { $0.id == storedSelectedProjectID } ? storedSelectedProjectID : nil
    }

    var suggestedProject: TaskProject? {
        guard let project = dailyTaskGroups.commonProjectSummaries(limit: 1).first?.project,
              selectedProjectID != project.id
        else { return nil }

        return projects.first { $0.id == project.id } ?? project
    }

    var showsSuggestedProjectButton: Bool {
        CreateReminderSubmission.normalizedText(from: message).isEmpty
            && suggestedProject != nil
    }

    var carryForwardReminders: [CreateReminder] {
        let currentReminderKeys = Set(reminders.map(CarryForwardReminderKey.init(reminder:)))

        return dailyTaskGroups
            .openRemindersFromPreviousDay(beforeDayID: dayID)
            .filter { !currentReminderKeys.contains(CarryForwardReminderKey(reminder: $0)) }
    }

    var showsCarryForwardButton: Bool {
        subscriptionTier.tier == .pro
            && CreateReminderSubmission.normalizedText(from: message).isEmpty
            && !carryForwardReminders.isEmpty
    }

    @ViewBuilder
    var suggestedProjectButton: some View {
        if let suggestedProject {
            Button {
                selectSuggestedProject(suggestedProject)
            } label: {
                HStack(spacing: NomaSpacing.sm) {
                    Image(systemName: suggestedProject.symbolName)
                        .font(.headline)
                        .foregroundStyle(suggestedProject.color)
                        .frame(width: ReminderInputBarLayout.minimumHeight)

                    Text(suggestedProjectTitle(for: suggestedProject))
                        .font(.headline)
                        .foregroundStyle(.textPrimary)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    var carryForwardButton: some View {
        Button(action: carryForwardOpenTasks) {
            HStack(spacing: NomaSpacing.sm) {
                Image(systemName: "chevron.down.forward.2")
                    .font(.headline)
                    .frame(width: ReminderInputBarLayout.minimumHeight)

                Text("create.carry-forward-yesterday.title")
                    .font(.headline)
            }
            .foregroundStyle(.textPrimary)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    func suggestedProjectTitle(for project: TaskProject) -> String {
        String.localizedStringWithFormat(
            String(localized: "create.suggested-project.title"),
            project.title
        )
    }

    func selectSuggestedProject(_ project: TaskProject) {
        selectedProjectID = project.id
        hapticFeedback.play(.createTaskSubmit)
        saveCurrentDailyGroup()
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

    nonisolated init(reminder: CreateReminder) {
        self.text = reminder.text
        self.projectID = reminder.projectID
    }
}
