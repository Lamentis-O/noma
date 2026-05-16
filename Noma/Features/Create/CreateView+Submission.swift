import SwiftUI

extension CreateView {
    var composerBar: some View {
        ReminderInputBar(
            text: $message,
            focus: $isInputFocused,
            placeholder: "create.input.placeholder",
            onTrayButtonTap: { isProjectSheetPresented = true },
            onSubmit: submitReminder
        )
    }

    func submitReminder() {
        guard let submission = CreateReminderSubmission.submit(text: message) else { return }

        message = submission.remainingText
        hapticFeedback.play(.createTaskSubmit)
        withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
            reminders.append(submission.reminder)
        }
    }

    func toggleReminder(_ reminder: CreateReminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        let updatedReminder = reminders[index].togglingCompletion()

        if let feedback = CreateReminderCompletionFeedback.feedback(isCompleted: updatedReminder.isCompleted) {
            hapticFeedback.play(feedback)
        }

        withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
            reminders[index] = updatedReminder
        }
    }

    var barSpacing: CGFloat { max(0, isKeyboardPresented ? focusedKeyboardSpacing : 0) }

    func barWidth(in proxy: GeometryProxy) -> CGFloat {
        let width = max(0, proxy.size.width - (barEdgePadding * 2))
        return width.isFinite ? width : 0
    }

    func barBottomPadding(in proxy: GeometryProxy) -> CGFloat {
        let padding = isKeyboardPresented ? focusedEdgePadding : max(0, collapsedEdgePadding - proxy.safeAreaInsets.bottom)
        return padding.isFinite ? padding : 0
    }

    var barEdgePadding: CGFloat { isKeyboardPresented ? focusedEdgePadding : collapsedEdgePadding }

    var projectSheet: some View {
        CreateSheet()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
    }
}
