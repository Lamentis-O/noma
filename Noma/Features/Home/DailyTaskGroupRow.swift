import SwiftUI

struct DailyTaskGroupRow: View {
    let summary: DailyTaskGroupSummary

    var body: some View {
        HStack(spacing: NomaSpacing.md) {
            VStack(alignment: .leading, spacing: NomaSpacing.xs) {
                Text(summary.title)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundStyle(.textPrimary)

                progressText
            }

            Spacer(minLength: 0)

            if let systemImage = DailyTaskGroupRowStatus.systemImage(for: summary) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.controlSuccess)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var progressText: some View {
        HStack(spacing: 0) {
            Text("\(summary.completedTaskCount) ")
            Text(LocalizedStringKey(DailyTaskGroupsProgressCopy.ofKey))
            Text(" \(summary.taskCount) ")
            Text(LocalizedStringKey(summary.taskCountUnitKey))
            Text(" ")
            Text(LocalizedStringKey(DailyTaskGroupsProgressCopy.doneKey))
        }
        .font(.headline)
        .fontWeight(.regular)
        .foregroundStyle(.textSecondary)
    }
}

enum DailyTaskGroupRowStatus {
    static let completedSystemImage = "checkmark.circle.fill"

    static func systemImage(for summary: DailyTaskGroupSummary) -> String? {
        summary.isCompleted ? completedSystemImage : nil
    }
}
