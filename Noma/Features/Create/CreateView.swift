import SwiftUI

struct CreateView: View {
    let collapsedEdgePadding = NomaSpacing.xl
    let focusedEdgePadding = NomaSpacing.md
    let focusedKeyboardSpacing = NomaSpacing.keyboardAccessoryOverlap
    let initialFocusDelay = NomaTiming.initialFocusDelay

    @Environment(\.hapticFeedback) var hapticFeedback
    @State var message = ""
    @State var reminders: [CreateReminder] = []
    @State var isKeyboardPresented = false
    @State var isProjectSheetPresented = false
    @FocusState var isInputFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                CreateReminderList(
                    reminders: reminders,
                    minimumHeight: CreateReminderListLayout.minimumHeight(for: proxy.size.height),
                    onToggleReminder: toggleReminder
                )
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background { Color.primaryBackground.ignoresSafeArea(.container) }
            .safeAreaBar(edge: .bottom, spacing: barSpacing) {
                composerBar
                    .frame(width: barWidth(in: proxy))
                    .padding(.bottom, barBottomPadding(in: proxy))
            }
        }
        .background { NavigationKeyboardDismissObserver(isInputFocused: $isInputFocused) }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardPresented = true
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
    }
}
