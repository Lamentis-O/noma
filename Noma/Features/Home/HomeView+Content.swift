import SwiftUI

extension HomeView {
    var createButton: some View {
        PrimaryGlassButton(title: "create.button.title", systemImage: "square.and.pencil") {
            path.append(.create(dayID: dailyTaskGroups.todayID()))
        }
    }

    var dailyGroupsList: some View {
        VStack(alignment: .leading, spacing: NomaSpacing.xxl) {
            if !todayReminders.isEmpty {
                HomeTodaySectionView(
                    reminders: todayReminders,
                    projects: todayProjects,
                    onToggleReminder: toggleTodayReminder,
                    onDeleteReminder: deleteTodayReminder,
                    onSwipeDeleteThreshold: {}
                )
            }

            if !commonProjectSummaries.isEmpty {
                CommonProjectsSectionView(
                    summaries: commonProjectSummaries,
                    onSelectProject: { path.append(.project($0.project.id)) }
                )
            }

            if !dailyGroupSummaries.isEmpty {
                DailyGroupsSectionView(
                    summaries: dailyGroupSummaries,
                    onSelectGroup: { path.append(.create(dayID: $0.id)) }
                )
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, NomaSpacing.xl)
        .padding(.top, NomaSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    var dailyGroupSummaries: [DailyTaskGroupSummary] { dailyTaskGroups.summaries() }
    var commonProjectSummaries: [CommonProjectSummary] { dailyTaskGroups.commonProjectSummaries() }
    var todayID: String { dailyTaskGroups.todayID() }
    var todayProjects: [TaskProject] { dailyTaskGroups.projects(forDayID: todayID) }
    var todayReminders: [CreateReminder] {
        dailyTaskGroups.reminders(forDayID: todayID).filter { !$0.isCompleted }
    }

    func toggleTodayReminder(_ reminder: CreateReminder) {
        var reminders = dailyTaskGroups.reminders(forDayID: todayID)
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        let updatedReminder = reminders[index].togglingCompletion()

        withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
            reminders[index] = updatedReminder
            dailyTaskGroups.save(reminders: reminders, forDayID: todayID)
        }
    }

    func deleteTodayReminder(_ reminder: CreateReminder) {
        var reminders = dailyTaskGroups.reminders(forDayID: todayID)
        reminders.removeAll { $0.id == reminder.id }
        withAnimation(.smooth(duration: NomaTiming.taskSwipeRelease)) {
            dailyTaskGroups.save(reminders: reminders, forDayID: todayID)
        }
    }

    func refreshDailyTaskNotifications() {
        let todayReminders = dailyTaskGroups.reminders(forDayID: dailyTaskGroups.todayID())
        Task { await dailyTaskNotifications.refreshDailyTaskReminders(for: todayReminders) }
    }
}
