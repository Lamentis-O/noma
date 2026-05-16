import SwiftUI

enum DailyMetricCardLayout {
    static let cornerRadius = NomaRadius.xl
    static let contentPadding = NomaSpacing.lg
    static let contentSpacing = NomaSpacing.xs
}

struct DailyMetricCard: View {
    let value: String
    let title: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: DailyMetricCardLayout.contentSpacing) {
            Text(value)
                .font(.headline)
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DailyMetricCardLayout.contentPadding)
        .background(
            .secondaryBackground,
            in: RoundedRectangle(
                cornerRadius: DailyMetricCardLayout.cornerRadius,
                style: .continuous
            )
        )
    }
}
