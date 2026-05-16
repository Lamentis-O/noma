import SwiftUI

enum CreateViewContentMode {
    static func usesScrollView(reminderCount: Int) -> Bool {
        !CreateReminderListSection.showsEmptyState(reminderCount: reminderCount)
    }
}

struct CreateView: View {
    let collapsedEdgePadding = NomaSpacing.xxl
    let focusedEdgePadding = NomaSpacing.md
    let focusedKeyboardSpacing = NomaOffset.keyboardAccessoryOverlap
    let initialFocusDelay = NomaTiming.initialFocusDelay

    @Environment(\.hapticFeedback) var hapticFeedback
    @Environment(SubscriptionTierManager.self) var subscriptionTier
    @State var message = ""
    @State var reminders: [CreateReminder] = []
    @State var isKeyboardPresented = false
    @State var isProjectSheetPresented = false
    @State var isUnlockMoreSheetPresented = false
    @State var pendingScrollTargetID: String?
    @FocusState var isInputFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(.primaryBackground)
                    .ignoresSafeArea(.container)

                content(in: proxy)
            }
            .safeAreaBar(edge: .bottom, spacing: barSpacing) {
                composerBar
                    .frame(width: barWidth(in: proxy))
                    .padding(.bottom, barBottomPadding(in: proxy))
            }
        }
        .background { NavigationKeyboardDismissObserver(isInputFocused: $isInputFocused) }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardPresented = true
            scrollToReminderListBottomAfterKeyboardFocus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardPresented = false
        }
        .task {
            guard await Self.shouldApplyInitialFocus({
                try await Task.sleep(nanoseconds: initialFocusDelay)
            }) else { return }
            isInputFocused = true
        }
        .sheet(isPresented: $isProjectSheetPresented) { projectSheet }
        .sheet(isPresented: $isUnlockMoreSheetPresented) { unlockMoreSheet }
    }
}
