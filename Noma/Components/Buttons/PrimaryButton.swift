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
                .font(.title3.weight(.bold))
                .foregroundStyle(.primaryBackground)
                .padding(.horizontal, NomaSpacing.buttonHorizontal)
                .padding(.vertical, NomaSpacing.md)
                .background {
                    Capsule().fill(color)
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
