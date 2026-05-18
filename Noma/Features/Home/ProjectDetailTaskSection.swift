import SwiftUI

struct ProjectDetailTaskSection: View {
    let title: String
    let reminders: [CreateReminder]
    let project: TaskProject?
    var headerColor: Color = .textPrimary
    var headerBottomPadding: CGFloat = SectionHeaderLayout.bottomPadding
    let onToggleReminder: (CreateReminder) -> Void
    let onDeleteReminder: (CreateReminder) -> Void
    let onSwipeDeleteThreshold: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CreateReminderSectionHeader(
                title: title,
                color: headerColor,
                bottomPadding: headerBottomPadding
            )

            VStack(alignment: .leading, spacing: NomaSpacing.md) {
                CreateReminderRows(
                    reminders: reminders,
                    projects: project.map { [$0] } ?? [],
                    onToggleReminder: onToggleReminder,
                    onDeleteReminder: onDeleteReminder,
                    onSwipeDeleteThreshold: onSwipeDeleteThreshold
                )
            }
        }
    }
}

extension ProjectDetailView {
    var composerBar: some View {
        ReminderInputBar(
            text: $message,
            focus: $isInputFocused,
            placeholder: "create.input.placeholder",
            isSubmissionAvailable: canSubmitReminder,
            traySystemImage: currentProject?.symbolName ?? "tray.full",
            trayColor: TaskProjectIconPresentation.appSurfaceColor,
            onTrayButtonTap: {},
            onSubmit: submitReminder
        )
    }
}
