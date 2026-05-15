import SwiftUI

struct PrimaryGlassButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
            }
            .font(.headline)
            .foregroundStyle(Color(.systemBackground))
            .padding(NomaSpacing.md)
        }
        .tint(.primary)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
    }
}
