import SwiftUI

struct CreateAIGeneratingStatus: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        HStack(spacing: NomaSpacing.sm) {
            ProgressView()
                .controlSize(.small)
                .tint(.textPrimary)
                .frame(width: ReminderInputBarLayout.minimumHeight)

            Text(titleKey)
                .font(.headline)
                .foregroundStyle(.textPrimary)
        }
        .accessibilityAddTraits(.updatesFrequently)
    }
}
