import SwiftUI

enum UnlockMoreCalloutLayout {
    static let contentSpacing = NomaSpacing.lg
    static let spacingFromPreviousContent = NomaSpacing.xxl

    static func topPadding(after stackSpacing: CGFloat) -> CGFloat {
        max(0, spacingFromPreviousContent - stackSpacing)
    }
}

struct UnlockMoreCallout: View {
    let messageKey: String
    let buttonTitleKey: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UnlockMoreCalloutLayout.contentSpacing) {
            Text(LocalizedStringKey(messageKey))
                .font(.body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            PrimaryButton(LocalizedStringKey(buttonTitleKey), action: action)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
