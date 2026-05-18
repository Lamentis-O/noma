import SwiftUI

struct CommonProjectsSectionView: View {
    let summaries: [CommonProjectSummary]
    let onSelectProject: (CommonProjectSummary) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(CommonProjectsSection.headerTitleKey)

            VStack(alignment: .leading, spacing: NomaSpacing.xl) {
                ForEach(summaries) { summary in
                    Button {
                        onSelectProject(summary)
                    } label: {
                        CommonProjectRow(summary: summary)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
}

struct CommonProjectRow: View {
    let summary: CommonProjectSummary

    var body: some View {
        HStack(spacing: NomaSpacing.md) {
            Image(systemName: summary.project.symbolName)
                .font(.headline)
                .foregroundStyle(TaskProjectIconPresentation.appSurfaceColor)
                .frame(width: NomaSize.projectControl, alignment: .center)

            Text(summary.project.title)
                .font(.headline)
                .foregroundStyle(.textPrimary)

            Spacer(minLength: 0)

            Text(CommonProjectsSection.taskCountText(for: summary))
                .font(.headline)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
