import SwiftUI

enum PrimaryButtonLayout {
    static let horizontalPadding = NomaSpacing.xl
    static let verticalPadding = NomaSpacing.md
}

enum PrimaryButtonFeedback {
    static let feedback: HapticFeedbackClass = .createTaskSubmit
}

struct PrimaryButton: View {
    let title: LocalizedStringKey
    let color: Color
    let action: () -> Void

    @Environment(\.hapticFeedback) private var hapticFeedback

    init(
        _ title: LocalizedStringKey,
        color: Color = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button {
            hapticFeedback.play(PrimaryButtonFeedback.feedback)
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primaryBackground)
                .padding(.horizontal, PrimaryButtonLayout.horizontalPadding)
                .padding(.vertical, PrimaryButtonLayout.verticalPadding)
                .background {
                    Capsule().fill(color)
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
