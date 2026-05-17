import SwiftUI

enum CreateViewContentMode {
    static func usesScrollView(reminderCount: Int) -> Bool {
        !CreateReminderListSection.showsEmptyState(reminderCount: reminderCount)
    }
}

struct CreateView: View {
    let dayID: String
    let collapsedEdgePadding = NomaSpacing.xxl
    let focusedEdgePadding = NomaSpacing.md
    let focusedKeyboardSpacing = NomaOffset.keyboardAccessoryOverlap

    @Environment(\.hapticFeedback) var hapticFeedback
    @Environment(SubscriptionTierManager.self) var subscriptionTier
    @Environment(DailyTaskGroupStore.self) var dailyTaskGroups
    @State var message = ""
    @State var reminders: [CreateReminder] = []
    @State var projects: [TaskProject] = []
    @State var selectedProjectID: TaskProject.ID?
    @State var isKeyboardPresented = false
    @State var isProjectSheetPresented = false
    @State var isUnlockMoreSheetPresented = false
    @State var showsOnlyUnsolvedTasks = false
    @State var pendingScrollTargetID: String?
    @FocusState var isInputFocused: Bool

    init(dayID: String = DailyTaskGroupStore.todayID()) {
        self.dayID = dayID
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(.primaryBackground)
                    .ignoresSafeArea(.container)

                content(in: proxy)
            }
            .safeAreaBar(edge: .bottom, spacing: barSpacing) {
                VStack(alignment: .leading, spacing: NomaSpacing.xl) {
                    if showsCarryForwardButton {
                        carryForwardButton
                            .padding(.leading, NomaSpacing.xl)
                    }

                    composerBar
                        .frame(width: barWidth(in: proxy))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, barBottomPadding(in: proxy))
            }
        }
        .background { NavigationKeyboardDismissObserver(isInputFocused: $isInputFocused) }
        .ignoresSafeArea(
            .keyboard,
            edges: isProjectSheetPresented || isUnlockMoreSheetPresented ? .bottom : []
        )
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            guard !isProjectSheetPresented, !isUnlockMoreSheetPresented else { return }
            isKeyboardPresented = true
            scrollToReminderListBottomAfterKeyboardFocus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            guard !isProjectSheetPresented, !isUnlockMoreSheetPresented else { return }
            isKeyboardPresented = false
        }
        .task {
            loadDailyGroup()
        }
        .navigationTitle(createNavigationTitle)
        .navigationSubtitle(createNavigationSubtitle)
        .toolbarTitleDisplayMode(.inline)
        .toolbar { createToolbar }
        .sheet(isPresented: $isProjectSheetPresented) { projectSheet }
        .sheet(isPresented: $isUnlockMoreSheetPresented) { unlockMoreSheet }
    }

    func loadDailyGroup() {
        reminders = dailyTaskGroups.reminders(forDayID: dayID)
        projects = dailyTaskGroups.projects(forDayID: dayID)

        let storedSelectedProjectID = dailyTaskGroups.selectedProjectID(forDayID: dayID)
        selectedProjectID = projects.contains { $0.id == storedSelectedProjectID } ? storedSelectedProjectID : nil
    }
}
