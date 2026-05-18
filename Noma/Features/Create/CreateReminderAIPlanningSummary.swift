import SwiftUI

struct CreateReminderAIPlanningSummary: View {
    let plan: CreateReminderAIPlanningResult
    let reminders: [CreateReminder]
    let carryForwardPreviewReminders: [CreateReminder]
    @State private var isPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: NomaSpacing.sm) {
            CreateReminderSectionHeader(
                title: String(localized: String.LocalizationValue(CreateReminderListSection.aiPlanTitleKey)),
                systemImage: "sparkles",
                bottomPadding: NomaSpacing.xs
            )

            Text(plan.summary)
                .font(.headline.weight(.regular))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let focusText {
                Text(focusText)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !plan.carryForwardReminderIDs.isEmpty {
                Text(carryForwardText)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.bottom, NomaSpacing.xl)
        .opacity(isPresented ? 1 : 0)
        .scaleEffect(isPresented ? 1 : NomaScale.pressedControl, anchor: .topLeading)
        .animation(.smooth(duration: NomaTiming.controlFeedback), value: isPresented)
        .onAppear { isPresented = true }
    }

    private var focusText: String? {
        guard let focusReminderID = plan.focusReminderID,
              let reminder = (reminders + carryForwardPreviewReminders).first(where: { $0.id == focusReminderID })
        else { return nil }

        let format = String(localized: String.LocalizationValue(CreateReminderListSection.aiPlanFocusKey))
        return String.localizedStringWithFormat(format, reminder.text)
    }

    private var carryForwardText: String {
        let format = String(localized: String.LocalizationValue(CreateReminderListSection.aiPlanCarryForwardKey))
        return String.localizedStringWithFormat(format, plan.carryForwardReminderIDs.count)
    }
}
