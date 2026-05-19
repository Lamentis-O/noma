import SwiftUI

struct HomeTodaySectionView: View {
    let reminders: [CreateReminder]
    let projects: [TaskProject]
    let onToggleReminder: (CreateReminder) -> Void
    let onDeleteReminder: (CreateReminder) -> Void
    let onSwipeDeleteThreshold: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CreateReminderSectionHeader(
                title: String(localized: String.LocalizationValue(HomeTodaySection.headerTitleKey))
            )

            CreateReminderRows(
                reminders: reminders,
                projects: projects,
                onToggleReminder: onToggleReminder,
                onDeleteReminder: onDeleteReminder,
                onSwipeDeleteThreshold: onSwipeDeleteThreshold
            )
        }
    }
}
