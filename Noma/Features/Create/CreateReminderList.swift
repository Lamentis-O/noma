import SwiftUI

enum CreateReminderListSection {
    static let headerTitleKey = "create.tasks.section-header"

    static func showsHeader(reminderCount: Int) -> Bool {
        reminderCount > 0
    }
}

enum CreateReminderListLayout {
    static let bottomScrollPadding = ReminderInputBarLayout.minimumHeight + NomaSpacing.xl

    static func minimumHeight(for viewportHeight: CGFloat) -> CGFloat {
        max(0, viewportHeight) + NomaSize.scrollDismissSentinel
    }
}

struct CreateReminderList: View {
    let reminders: [CreateReminder]
    let minimumHeight: CGFloat
    let onToggleReminder: (CreateReminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if CreateReminderListSection.showsHeader(reminderCount: reminders.count) {
                SectionHeader(CreateReminderListSection.headerTitleKey)
            }

            VStack(alignment: .leading, spacing: NomaSpacing.md) {
                ForEach(reminders) { reminder in
                    Button {
                        onToggleReminder(reminder)
                    } label: {
                        CreateReminderRow(reminder: reminder)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .padding(.horizontal, NomaSpacing.xl)
        .padding(.top, NomaSpacing.xl)
        .padding(.bottom, CreateReminderListLayout.bottomScrollPadding)
        .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .topLeading)
    }
}

private struct CreateReminderRow: View {
    let reminder: CreateReminder

    var body: some View {
        HStack(alignment: .top, spacing: NomaSpacing.md) {
            Text(reminder.text)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            RadioCheckbox(isOn: reminder.isCompleted)
                .padding(.top, RadioCheckboxLayout.firstLineCenterOffset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
