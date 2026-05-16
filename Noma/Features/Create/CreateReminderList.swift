import SwiftUI

enum CreateReminderListSection {
    static let headerTitleKey = "create.tasks.section-header", unlockMoreTitleKey = "create.tasks.unlock-more", unlockMoreMessageKey = "create.tasks.unlock-more.message"

    static func showsHeader(reminderCount: Int) -> Bool { reminderCount > 0 }
    static func showsEmptyState(reminderCount: Int) -> Bool { reminderCount == 0 }

    static func showsUnlockMoreButton(tier: SubscriptionTier, reminderCount: Int) -> Bool {
        !tier.canAddTask(toGroupWithTaskCount: reminderCount)
    }
}

enum CreateReminderLimitCalloutLayout {
    static let spacingFromTasks = NomaSpacing.xl, contentSpacing = NomaSpacing.md

    static var topPadding: CGFloat { spacingFromTasks - NomaSpacing.md }
}

enum CreateReminderListLayout {
    static let bottomScrollPadding = NomaSpacing.xl, bottomAnchorID = "create-reminder-list-bottom-anchor"
    static func minimumHeight(for viewportHeight: CGFloat) -> CGFloat { max(0, viewportHeight) + NomaSize.scrollDismissSentinel }
}

enum CreateReminderAutoScroll {
    static func targetAfterAppending(_: CreateReminder) -> String { CreateReminderListLayout.bottomAnchorID }

    static func targetAfterKeyboardFocus(reminderCount: Int) -> String? {
        guard reminderCount > 0 else { return nil }
        return CreateReminderListLayout.bottomAnchorID
    }
}

enum CreateReminderSwipeAction {
    static let deleteThreshold = NomaSize.taskDeleteSwipeThreshold, minimumDistance: CGFloat = 0

    static func shouldTrackSwipe(translation: CGSize) -> Bool {
        translation.width < 0 && abs(translation.width) >= abs(translation.height)
    }

    static func offset(for translation: CGFloat) -> CGFloat {
        max(-deleteThreshold, min(0, translation * NomaScale.taskDeleteSwipeDamping))
    }

    static func progress(for offset: CGFloat) -> CGFloat {
        guard deleteThreshold > 0 else { return 0 }
        return min(CreateReminderSwipeAction.deleteThreshold / deleteThreshold, abs(offset) / deleteThreshold)
    }

    static func remainingProgress(for offset: CGFloat) -> CGFloat {
        progress(for: -deleteThreshold) - progress(for: offset)
    }

    static func shouldDelete(offset: CGFloat) -> Bool { abs(offset) >= deleteThreshold }

    static func feedback(previousOffset: CGFloat, currentOffset: CGFloat) -> HapticFeedbackClass? {
        !shouldDelete(offset: previousOffset) && shouldDelete(offset: currentOffset) ? .createTaskSubmit : nil
    }
}

struct CreateTaskEmptyState {
    let systemImage: String?
    let titleKey: String, subtitleKey: String
    let cta: HintCTA?
    let mirrorsImageForRightToLeftLayoutDirection: Bool

    static let placeholder = CreateTaskEmptyState(systemImage: nil, titleKey: "create.tasks.empty.title", subtitleKey: "create.tasks.empty.subtitle", cta: nil, mirrorsImageForRightToLeftLayoutDirection: false)
}

struct CreateTaskEmptyHint: View {
    var body: some View {
        HintView(
            systemImage: CreateTaskEmptyState.placeholder.systemImage,
            title: LocalizedStringKey(CreateTaskEmptyState.placeholder.titleKey),
            subtitle: LocalizedStringKey(CreateTaskEmptyState.placeholder.subtitleKey),
            cta: CreateTaskEmptyState.placeholder.cta,
            mirrorsSystemImageForRightToLeftLayoutDirection: CreateTaskEmptyState.placeholder.mirrorsImageForRightToLeftLayoutDirection
        )
    }
}

struct CreateReminderLimitCallout: View {
    let onUnlockMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CreateReminderLimitCalloutLayout.contentSpacing) {
            Text(LocalizedStringKey(CreateReminderListSection.unlockMoreMessageKey))
                .font(.body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            PrimaryButton(LocalizedStringKey(CreateReminderListSection.unlockMoreTitleKey), action: onUnlockMore)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CreateReminderRow: View {
    let reminder: CreateReminder
    let onToggle: () -> Void, onDelete: () -> Void, onSwipeDeleteThreshold: () -> Void

    @State private var swipeOffset: CGFloat = 0
    @State private var isSwipeActive = false

    var body: some View {
        HStack(alignment: .top, spacing: NomaSpacing.md) {
            ZStack(alignment: .leading) {
                reminderText(.textPrimary).opacity(remainingSwipeProgress)
                reminderText(.textSecondary).opacity(swipeProgress)
            }

            swipeActionControl
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .simultaneousGesture(swipeGesture)
    }

    private var swipeProgress: CGFloat { CreateReminderSwipeAction.progress(for: swipeOffset) }
    private var remainingSwipeProgress: CGFloat { CreateReminderSwipeAction.remainingProgress(for: swipeOffset) }
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: CreateReminderSwipeAction.minimumDistance)
            .onChanged(updateSwipeOffset)
            .onEnded(finishSwipe)
    }

    private var swipeActionControl: some View {
        ZStack {
            deleteIcon
            RadioCheckbox(isOn: reminder.isCompleted)
                .opacity(remainingSwipeProgress).scaleEffect(remainingSwipeProgress, anchor: .center)
        }
        .frame(width: NomaSize.radioCheckboxOuter, height: NomaSize.radioCheckboxOuter, alignment: .center)
        .padding(.top, RadioCheckboxLayout.firstLineCenterOffset)
    }

    private var deleteIcon: some View {
        Image(systemName: "minus.circle.fill")
            .font(.body)
            .foregroundStyle(.controlError)
            .opacity(swipeProgress).scaleEffect(deleteIconScale, anchor: .center)
            .frame(width: NomaSize.radioCheckboxOuter, height: NomaSize.radioCheckboxOuter, alignment: .center)
            .accessibilityHidden(true)
    }

    private func reminderText(_ color: Color) -> some View {
        Text(reminder.text)
            .font(.body)
            .foregroundStyle(color)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var deleteIconScale: CGFloat {
        NomaScale.pressedControl + ((CreateReminderSwipeAction.progress(for: -CreateReminderSwipeAction.deleteThreshold) - NomaScale.pressedControl) * swipeProgress)
    }

    private func updateSwipeOffset(with value: DragGesture.Value) {
        guard isSwipeActive || CreateReminderSwipeAction.shouldTrackSwipe(translation: value.translation) else { return }
        isSwipeActive = true

        let nextOffset = CreateReminderSwipeAction.offset(for: value.translation.width)
        if CreateReminderSwipeAction.feedback(previousOffset: swipeOffset, currentOffset: nextOffset) != nil {
            onSwipeDeleteThreshold()
        }
        swipeOffset = nextOffset
    }

    private func finishSwipe(with _: DragGesture.Value) {
        guard isSwipeActive else {
            swipeOffset = 0
            return
        }

        isSwipeActive = false
        guard CreateReminderSwipeAction.shouldDelete(offset: swipeOffset) else {
            withAnimation(.smooth(duration: NomaTiming.taskSwipeRelease)) { swipeOffset = 0 }
            return
        }

        withAnimation(.smooth(duration: NomaTiming.taskSwipeRelease)) { swipeOffset = -CreateReminderSwipeAction.deleteThreshold }
        onDelete()
    }
}

struct CreateReminderList: View {
    let reminders: [CreateReminder]
    let minimumHeight: CGFloat
    let tier: SubscriptionTier
    let onUnlockMore: () -> Void, onSwipeDeleteThreshold: () -> Void
    let onToggleReminder: (CreateReminder) -> Void, onDeleteReminder: (CreateReminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if CreateReminderListSection.showsHeader(reminderCount: reminders.count) {
                SectionHeader(CreateReminderListSection.headerTitleKey)
            }

            VStack(alignment: .leading, spacing: NomaSpacing.md) {
                ForEach(reminders) { reminder in
                    CreateReminderRow(
                        reminder: reminder,
                        onToggle: { onToggleReminder(reminder) },
                        onDelete: { onDeleteReminder(reminder) },
                        onSwipeDeleteThreshold: onSwipeDeleteThreshold
                    )
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity.combined(with: .move(edge: .leading))))
                }

                if CreateReminderListSection.showsUnlockMoreButton(tier: tier, reminderCount: reminders.count) {
                    CreateReminderLimitCallout(onUnlockMore: onUnlockMore)
                        .padding(.top, CreateReminderLimitCalloutLayout.topPadding)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: CreateReminderListLayout.bottomScrollPadding)
                    .frame(height: CreateReminderListLayout.bottomScrollPadding)
                    .id(CreateReminderListLayout.bottomAnchorID)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, NomaSpacing.xxl)
        .padding(.top, NomaSpacing.xxl)
        .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .topLeading)
    }
}
