import SwiftUI

extension CreateSheet {
    @ViewBuilder
    var content: some View {
        if projects.isEmpty {
            VStack {
                Spacer(minLength: 0)
                HintView(
                    systemImage: emptyState.systemImage,
                    title: emptyState.title,
                    subtitle: emptyState.subtitle,
                    cta: emptyState.cta
                )
                Spacer(minLength: 0)
            }
        } else {
            CreateProjectList(
                projects: visibleProjects,
                projectCount: projects.count,
                selectedProjectID: selectedProjectID,
                allReminders: allReminders,
                tier: tier,
                onSelectProject: selectProject,
                onEditProject: editProject,
                onDeleteProject: deleteProject,
                onUnlockMore: unlockMoreProjects
            )
        }
    }

    var visibleProjects: [TaskProject] {
        projects
    }

    func selectProject(_ projectID: TaskProject.ID?) {
        onSelectProject(projectID)
        dismiss()
    }

    func editProject(_ project: TaskProject) {
        projectEditorPresentation = .edit(project)
    }

    func deleteProject(_ projectID: TaskProject.ID) { pendingDeleteProjectID = projectID }

    func confirmProjectDeletion() {
        guard let pendingDeleteProjectID else { return }
        onDeleteProject(pendingDeleteProjectID)
        self.pendingDeleteProjectID = nil
    }

    var deleteConfirmationBinding: Binding<Bool> {
        Binding {
            pendingDeleteProjectID != nil
        } set: { isPresented in
            if !isPresented {
                pendingDeleteProjectID = nil
            }
        }
    }

    func openAddProjectSheet() {
        projectEditorPresentation = .add
    }

    func unlockMoreProjects() {
        #if DEBUG
        onUnlockMore()
        #else
        isUnlockMoreSheetPresented = true
        #endif
    }

    func saveProject(_ project: TaskProject) {
        if case .edit = projectEditorPresentation {
            onUpdateProject(project)
        } else {
            onCreateProject(project)
        }
        projectEditorPresentation = nil
    }

    var emptyState: CreateProjectEmptyState {
        .placeholder
    }
}
