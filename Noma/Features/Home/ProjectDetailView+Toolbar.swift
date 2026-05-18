import SwiftUI

extension ProjectDetailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            TaskNavigationTitleButton(
                title: navigationTitle,
                subtitle: navigationSubtitle,
                accessibilityLabelKey: "create.project.edit.title",
                action: { isEditProjectSheetPresented = currentProject != nil }
            )
        }

        ToolbarItem(placement: .topBarTrailing) {
            TaskDoneToolbarButton(
                isDisabled: !canCompleteAllReminders,
                action: completeAllRemindersForProject
            )
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
            TaskFilterToolbarButton(
                isActive: showsOnlyUnsolvedTasks,
                isDisabled: projectSummary.taskCount == 0,
                action: toggleUnsolvedFilter
            )
        }
    }

    @ViewBuilder
    var editProjectSheet: some View {
        if let currentProject {
            AddProjectSheet(project: currentProject) { updatedProject in
                dailyTaskGroups.updateProject(updatedProject)
                project = updatedProject
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationContentInteraction(.resizes)
        }
    }
}
