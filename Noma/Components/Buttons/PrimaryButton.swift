import SwiftUI

struct PrimaryButton: View {
    let title: LocalizedStringKey
    let color: Color
    let action: () -> Void

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
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primaryBackground)
                .padding(.horizontal, NomaSpacing.lg)
                .padding(.vertical, NomaSpacing.sm)
                .background {
                    Capsule().fill(color)
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
