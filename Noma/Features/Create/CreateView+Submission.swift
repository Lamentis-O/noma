import SwiftUI

extension CreateView {
    var composerBar: some View {
        ReminderInputBar(
            text: $message,
            focus: $isInputFocused,
            placeholder: "create.input.placeholder",
            isSubmissionAvailable: canSubmitReminder,
            traySystemImage: selectedProject?.symbolName ?? "tray.full",
            trayColor: selectedProject?.color ?? .primary,
            onTrayButtonTap: { isProjectSheetPresented = true },
            onSubmit: submitReminder
        )
    }

    var selectedProject: TaskProject? {
        projects.first { $0.id == selectedProjectID }
    }

    func submitReminder(_ submittedText: String) {
        guard canSubmitReminder else { return }
        guard let submission = CreateReminderSubmission.submit(
            text: submittedText,
            projectID: selectedProjectID
        ) else { return }

        message = submission.remainingText
        hapticFeedback.play(.createTaskSubmit)
        withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
            reminders.append(submission.reminder)
        }
        saveCurrentReminders()
        pendingScrollTargetID = CreateReminderAutoScroll.targetAfterAppending(submission.reminder)
    }

    var canSubmitReminder: Bool {
        subscriptionTier.tier.canAddTask(toGroupWithTaskCount: reminders.count)
    }

    func unlockMoreTasks() {
        #if DEBUG
        subscriptionTier.debugUnlockPro()
        #else
        isUnlockMoreSheetPresented = true
        #endif
    }

    func unlockMoreProjects() {
        #if DEBUG
        subscriptionTier.debugUnlockPro()
        #else
        isUnlockMoreSheetPresented = true
        #endif
    }

    func addProject(_ project: TaskProject) {
        projects.append(project)
        selectedProjectID = project.id
        saveCurrentDailyGroup()
    }

    func updateProject(_ project: TaskProject) {
        dailyTaskGroups.updateProject(project)
        projects = dailyTaskGroups.projects(forDayID: dayID)
    }

    func deleteProject(_ projectID: TaskProject.ID) {
        dailyTaskGroups.deleteProject(withID: projectID)

        withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
            reminders = dailyTaskGroups.reminders(forDayID: dayID)
        }
        projects = dailyTaskGroups.projects(forDayID: dayID)
        selectedProjectID = dailyTaskGroups.selectedProjectID(forDayID: dayID)
    }

    func selectProject(_ projectID: TaskProject.ID?) {
        selectedProjectID = projectID
        saveCurrentDailyGroup()
    }

    func scrollToReminderListBottomAfterKeyboardFocus() {
        guard let targetID = CreateReminderAutoScroll.targetAfterKeyboardFocus(reminderCount: reminders.count) else {
            return
        }

        pendingScrollTargetID = targetID
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
        saveCurrentDailyGroup()
    }

    func deleteReminder(_ reminder: CreateReminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }

        withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
            _ = reminders.remove(at: index)
        }
        saveCurrentDailyGroup()
    }

    func saveCurrentReminders() {
        saveCurrentDailyGroup()
    }

    func saveCurrentDailyGroup() {
        dailyTaskGroups.save(
            reminders: reminders,
            projects: projects,
            selectedProjectID: selectedProjectID,
            forDayID: dayID
        )
    }

    func playSwipeDeleteThresholdFeedback() {
        hapticFeedback.play(.createTaskSubmit)
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
        CreateSheet(
            projects: $projects,
            selectedProjectID: $selectedProjectID,
            reminders: reminders,
            tier: subscriptionTier.tier,
            onCreateProject: addProject,
            onSelectProject: selectProject,
            onUpdateProject: updateProject,
            onDeleteProject: deleteProject,
            onUnlockMore: unlockMoreProjects
        )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationContentInteraction(.resizes)
    }

    var unlockMoreSheet: some View {
        NavigationStack {
            Rectangle()
                .fill(.primaryBackground)
                .ignoresSafeArea(.container)
                .navigationTitle(LocalizedStringKey("create.unlock-more.sheet.title"))
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isUnlockMoreSheetPresented = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel(Text("create.unlock-more.close.accessibility-label"))
                    }
                }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    func content(in proxy: GeometryProxy) -> some View {
        if CreateViewContentMode.usesScrollView(reminderCount: reminders.count) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    CreateReminderList(
                        reminders: reminders,
                        projects: projects,
                        minimumHeight: CreateReminderListLayout.minimumHeight(for: proxy.size.height),
                        tier: subscriptionTier.tier,
                        onUnlockMore: unlockMoreTasks,
                        onSwipeDeleteThreshold: playSwipeDeleteThresholdFeedback,
                        onToggleReminder: toggleReminder,
                        onDeleteReminder: deleteReminder
                    )
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .task(id: pendingScrollTargetID) {
                    await scrollToPendingTarget(using: scrollProxy)
                }
            }
        } else {
            CreateTaskEmptyHint()
                .padding(.horizontal, NomaSpacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    @MainActor
    func scrollToPendingTarget(using scrollProxy: ScrollViewProxy) async {
        guard let pendingScrollTargetID else { return }

        await Task.yield()
        withAnimation(.smooth(duration: NomaTiming.controlFeedback)) {
            scrollProxy.scrollTo(pendingScrollTargetID, anchor: .bottom)
        }
        self.pendingScrollTargetID = nil
    }
}
