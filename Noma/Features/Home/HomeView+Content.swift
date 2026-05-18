import SwiftUI

extension HomeView {
    var createButton: some View {
        PrimaryGlassButton(title: "create.button.title", systemImage: "square.and.pencil") {
            path.append(.create(dayID: dailyTaskGroups.todayID()))
        }
    }

    var dailyGroupsList: some View {
        VStack(alignment: .leading, spacing: NomaSpacing.xxl) {
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

    func refreshDailyTaskNotifications() {
        let todayReminders = dailyTaskGroups.reminders(forDayID: dailyTaskGroups.todayID())
        Task { await dailyTaskNotifications.refreshDailyTaskReminders(for: todayReminders) }
    }
}
