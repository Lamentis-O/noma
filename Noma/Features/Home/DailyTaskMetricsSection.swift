import SwiftUI

enum DailyTaskMetricsSectionVisibility {
    static func isVisible(for tier: SubscriptionTier) -> Bool {
        tier == .pro
    }
}

enum DailyTaskMetricsSectionLayout {
    static let cardSpacing = NomaSpacing.md
}

struct DailyTaskMetricsSection: View {
    let metrics: DailyTaskMetrics

    var body: some View {
        HStack(spacing: DailyTaskMetricsSectionLayout.cardSpacing) {
            DailyMetricCard(
                value: "\(metrics.todayCompletedCount) of \(metrics.todayTargetCount)",
                title: "home.metrics.today.title"
            )

            DailyMetricCard(
                value: "\(metrics.streakCount)",
                title: "home.metrics.streak.title"
            )
        }
    }
}
