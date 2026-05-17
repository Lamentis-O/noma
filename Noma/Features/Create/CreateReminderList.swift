import SwiftUI
import UIKit

enum CreateReminderListSection {
    static let headerTitleKey = "create.tasks.today.section-header", unlockMoreTitleKey = "create.tasks.unlock-more", unlockMoreMessageKey = "create.tasks.unlock-more.today.message"

    static func showsHeader(reminderCount: Int) -> Bool { reminderCount > 0 }
    static func showsEmptyState(reminderCount: Int) -> Bool { reminderCount == 0 }

    static func showsUnlockMoreButton(tier: SubscriptionTier, reminderCount: Int) -> Bool {
        !tier.canAddTask(toGroupWithTaskCount: reminderCount)
    }
}

enum CreateReminderLimitCalloutLayout {
    static var topPadding: CGFloat { UnlockMoreCalloutLayout.topPadding(after: NomaSpacing.md) }
}

enum CreateReminderListLayout {
    static let bottomScrollPadding = NomaSpacing.xl, bottomAnchorID = "create-reminder-list-bottom-anchor"
    static func minimumHeight(for viewportHeight: CGFloat) -> CGFloat { max(0, viewportHeight) + NomaSize.scrollDismissSentinel }
}

enum CreateReminderMetadataIconLayout {
    static let columnWidth = NomaSize.taskMetadataIconColumn
    static let spacingToText = NomaSpacing.md
    static let firstLineCenterOffset = NomaSize.taskFirstLineIconOffset
}

struct CreateReminderSectionHeader: View {
    let titleKey: String

    var body: some View {
        HStack(alignment: .center, spacing: CreateReminderMetadataIconLayout.spacingToText) {
            Image(systemName: "checklist.unchecked")
                .font(.headline)
                .frame(
                    width: CreateReminderMetadataIconLayout.columnWidth,
                    height: NomaSize.radioCheckboxOuter,
                    alignment: .center
                )

            Text(displayText)
                .font(.headline)
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, SectionHeaderLayout.bottomPadding)
    }

    private var displayText: String {
        let localizedText = String(localized: String.LocalizationValue(titleKey))
        return SectionHeaderTextFormatting.titleCased(localizedText)
    }
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
    static let horizontalActivationBias = NomaSpacing.xs

    static func shouldTrackSwipe(translation: CGSize) -> Bool {
        translation.width < 0 && abs(translation.width) > abs(translation.height) + horizontalActivationBias
    }

    static func shouldBeginSwipe(translation: CGSize, velocity: CGSize) -> Bool {
        let horizontalVelocity = abs(velocity.width)
        let verticalVelocity = abs(velocity.height)

        return translation.width < 0
            && horizontalVelocity > verticalVelocity * NomaScale.taskSwipeHorizontalDominance
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

    static let placeholder = CreateTaskEmptyState(systemImage: nil, titleKey: "create.tasks.empty.today.title", subtitleKey: "create.tasks.empty.today.subtitle", cta: nil, mirrorsImageForRightToLeftLayoutDirection: false)
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

struct CreateReminderProjectIcon: View {
    let project: TaskProject?

    var body: some View {
        ZStack(alignment: .center) {
            if let project {
                Image(systemName: project.symbolName)
                    .font(.headline)
                    .foregroundStyle(project.color)
            }
        }
        .frame(
            width: CreateReminderMetadataIconLayout.columnWidth,
            height: NomaSize.radioCheckboxOuter,
            alignment: .center
        )
        .padding(.top, CreateReminderMetadataIconLayout.firstLineCenterOffset)
    }
}

struct CreateReminderRowGestureOverlay: UIViewRepresentable {
    var onTap: () -> Void
    var onSwipeChanged: (CGSize) -> Void
    var onSwipeEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap, onSwipeChanged: onSwipeChanged, onSwipeEnded: onSwipeEnded)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = context.coordinator
        view.addGestureRecognizer(panGesture)

        return view
    }

    func updateUIView(_: UIView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onSwipeChanged = onSwipeChanged
        context.coordinator.onSwipeEnded = onSwipeEnded
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: () -> Void
        var onSwipeChanged: (CGSize) -> Void
        var onSwipeEnded: () -> Void

        init(
            onTap: @escaping () -> Void,
            onSwipeChanged: @escaping (CGSize) -> Void,
            onSwipeEnded: @escaping () -> Void
        ) {
            self.onTap = onTap
            self.onSwipeChanged = onSwipeChanged
            self.onSwipeEnded = onSwipeEnded
        }

        @objc func handleTap() {
            onTap()
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began, .changed:
                let translation = gesture.translation(in: gesture.view)
                onSwipeChanged(CGSize(width: translation.x, height: translation.y))
            case .ended, .cancelled, .failed:
                onSwipeEnded()
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let translation = panGesture.translation(in: panGesture.view)
            let velocity = panGesture.velocity(in: panGesture.view)
            return CreateReminderSwipeAction.shouldBeginSwipe(
                translation: CGSize(width: translation.x, height: translation.y),
                velocity: CGSize(width: velocity.x, height: velocity.y)
            )
        }

        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

struct CreateReminderRow: View {
    let reminder: CreateReminder
    let project: TaskProject?
    let onToggle: () -> Void, onDelete: () -> Void, onSwipeDeleteThreshold: () -> Void

    @State private var swipeOffset: CGFloat = 0
    @State private var isSwipeActive = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            CreateReminderProjectIcon(project: project)
                .padding(.trailing, CreateReminderMetadataIconLayout.spacingToText)

            ZStack(alignment: .leading) {
                reminderText(.textPrimary).opacity(remainingSwipeProgress)
                reminderText(.textSecondary).opacity(swipeProgress)
            }

            swipeActionControl
                .padding(.leading, NomaSpacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .overlay {
            CreateReminderRowGestureOverlay(
                onTap: onToggle,
                onSwipeChanged: updateSwipeOffset,
                onSwipeEnded: finishSwipe
            )
        }
    }

    private var swipeProgress: CGFloat { CreateReminderSwipeAction.progress(for: swipeOffset) }
    private var remainingSwipeProgress: CGFloat { CreateReminderSwipeAction.remainingProgress(for: swipeOffset) }

    private var swipeActionControl: some View {
        ZStack {
            deleteIcon
            RadioCheckbox(isOn: reminder.isCompleted)
                .opacity(remainingSwipeProgress).scaleEffect(remainingSwipeProgress, anchor: .center)
        }
        .frame(width: NomaSize.radioCheckboxOuter, height: NomaSize.radioCheckboxOuter, alignment: .center)
        .padding(.top, CreateReminderMetadataIconLayout.firstLineCenterOffset)
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
            .font(.headline.weight(.regular))
            .foregroundStyle(color)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var deleteIconScale: CGFloat {
        NomaScale.pressedControl + ((CreateReminderSwipeAction.progress(for: -CreateReminderSwipeAction.deleteThreshold) - NomaScale.pressedControl) * swipeProgress)
    }

    private func updateSwipeOffset(with translation: CGSize) {
        guard isSwipeActive || CreateReminderSwipeAction.shouldTrackSwipe(translation: translation) else { return }
        isSwipeActive = true

        let nextOffset = CreateReminderSwipeAction.offset(for: translation.width)
        if CreateReminderSwipeAction.feedback(previousOffset: swipeOffset, currentOffset: nextOffset) != nil {
            onSwipeDeleteThreshold()
        }
        swipeOffset = nextOffset
    }

    private func finishSwipe() {
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
    let reminderCount: Int
    let projects: [TaskProject]
    let minimumHeight: CGFloat
    let tier: SubscriptionTier
    let onUnlockMore: () -> Void, onSwipeDeleteThreshold: () -> Void
    let onToggleReminder: (CreateReminder) -> Void, onDeleteReminder: (CreateReminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if CreateReminderListSection.showsHeader(reminderCount: reminderCount) {
                CreateReminderSectionHeader(titleKey: CreateReminderListSection.headerTitleKey)
            }

            VStack(alignment: .leading, spacing: NomaSpacing.md) {
                ForEach(reminders) { reminder in
                    CreateReminderRow(
                        reminder: reminder,
                        project: project(for: reminder),
                        onToggle: { onToggleReminder(reminder) },
                        onDelete: { onDeleteReminder(reminder) },
                        onSwipeDeleteThreshold: onSwipeDeleteThreshold
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        )
                    )
                }

                if CreateReminderListSection.showsUnlockMoreButton(tier: tier, reminderCount: reminderCount) {
                    UnlockMoreCallout(
                        messageKey: CreateReminderListSection.unlockMoreMessageKey,
                        buttonTitleKey: CreateReminderListSection.unlockMoreTitleKey,
                        action: onUnlockMore
                    )
                        .padding(.top, CreateReminderLimitCalloutLayout.topPadding)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: CreateReminderListLayout.bottomScrollPadding)
                    .frame(height: CreateReminderListLayout.bottomScrollPadding)
                    .id(CreateReminderListLayout.bottomAnchorID)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, NomaSpacing.xl)
        .padding(.top, NomaSpacing.xxl)
        .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .topLeading)
    }

    private func project(for reminder: CreateReminder) -> TaskProject? {
        guard let projectID = reminder.projectID else { return nil }
        return projects.first { $0.id == projectID }
    }
}
