import SwiftUI

struct CommonProjectsSectionView: View {
    let summaries: [CommonProjectSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: NomaSpacing.xl) {
            ForEach(summaries) { summary in
                CommonProjectRow(summary: summary)
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

            Text(summary.project.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.textPrimary)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
