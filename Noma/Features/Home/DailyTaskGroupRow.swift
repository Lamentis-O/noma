import SwiftUI

enum DailyTaskGroupRowInteraction {
    static let usesScaleButtonStyle = true
}

enum DailyTaskGroupRowLayout {
    static let completedIconAdditionalTrailingPadding = NomaSpacing.xs
}

struct DailyTaskGroupRow: View {
    let summary: DailyTaskGroupSummary

    var body: some View {
        HStack(spacing: NomaSpacing.md) {
            VStack(alignment: .leading, spacing: NomaSpacing.xs) {
                Text(summary.title)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundStyle(.textPrimary)

                DailyTaskGroupProgressText(summary: summary)
            }

            Spacer(minLength: 0)

            if let systemImage = DailyTaskGroupRowStatus.systemImage(for: summary) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.controlSuccess)
                    .padding(.trailing, DailyTaskGroupRowLayout.completedIconAdditionalTrailingPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

}

struct DailyTaskGroupProgressText: View {
    let summary: DailyTaskGroupSummary

    var body: some View {
        Text(DailyTaskGroupsProgressCopy.title(for: summary))
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
