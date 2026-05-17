import SwiftUI

struct CommonProjectsSectionView: View {
    let summaries: [CommonProjectSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(CommonProjectsSection.headerTitleKey)

            VStack(alignment: .leading, spacing: NomaSpacing.xl) {
                ForEach(summaries) { summary in
                    CommonProjectRow(summary: summary)
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
                .font(.headline.weight(.bold))
                .foregroundStyle(summary.project.color)
                .frame(width: NomaSize.projectControl, height: NomaSize.projectControl)
                .background {
                    Circle().fill(.secondaryBackground)
                }

            VStack(alignment: .leading, spacing: NomaSpacing.xs) {
                Text(summary.project.title)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundStyle(.textPrimary)

                CommonProjectStatsText(summary: summary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CommonProjectStatsText: View {
    let summary: CommonProjectSummary

    var body: some View {
        HStack(spacing: 0) {
            Text("\(summary.taskCount) ")
            Text(LocalizedStringKey(summary.taskUnitKey))
            Text(", \(summary.unsolvedTaskCount) ")
            Text(LocalizedStringKey(TaskProjectStatsCopy.unsolvedKey))
        }
        .font(.headline)
        .fontWeight(.regular)
        .foregroundStyle(.textSecondary)
    }
}
