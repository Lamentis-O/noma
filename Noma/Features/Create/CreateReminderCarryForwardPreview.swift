import SwiftUI
import UIKit

enum CreateReminderCarryForwardPreview {
    static func visibleReminders(
        currentReminders: [CreateReminder],
        previousOpenReminders: [CreateReminder]
    ) -> [CreateReminder] {
        let currentReminderKeys = Set(currentReminders.map(CarryForwardReminderKey.init(reminder:)))
        return previousOpenReminders.filter { !currentReminderKeys.contains(CarryForwardReminderKey(reminder: $0)) }
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

struct CreateReminderCarryForwardPreviewRow: View {
    let reminder: CreateReminder
    let project: TaskProject?
    let onComplete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            CreateReminderProjectIcon(project: project, color: .textSecondary)
                .padding(.trailing, CreateReminderMetadataIconLayout.spacingToText)

            Text(reminder.text)
                .font(.headline.weight(.regular))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            RadioCheckbox(
                isOn: false,
                borderColor: .textSecondary,
                fillColor: .textSecondary
            )
            .padding(.leading, NomaSpacing.md)
            .padding(.top, CreateReminderMetadataIconLayout.firstLineCenterOffset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .overlay {
            CreateReminderRowGestureOverlay(
                onTap: onComplete,
                onSwipeChanged: { _ in },
                onSwipeEnded: {}
            )
        }
    }
}

enum CreateReminderCarryForwardCompletion {
    static func completing(_ reminder: CreateReminder, in reminders: [CreateReminder]) -> [CreateReminder] {
        reminders.map { storedReminder in
            storedReminder.id == reminder.id && !storedReminder.isCompleted
                ? storedReminder.togglingCompletion()
                : storedReminder
        }
    }
}

struct CreateReminderRowGestureOverlay: UIViewRepresentable {
    var onTap: () -> Void
    var onSwipeChanged: (CGSize) -> Void
    var onSwipeEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTap: onTap,
            onSwipeChanged: onSwipeChanged,
            onSwipeEnded: onSwipeEnded
        )
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

        @objc func handleTap() { onTap() }

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

        func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
