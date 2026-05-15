import SwiftUI

struct CreateSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Spacer(minLength: 0)

                HintView(
                    systemImage: "tray.full",
                    title: "create.project.empty.title",
                    subtitle: "create.project.empty.subtitle",
                    cta: HintCTA(title: "create.project.empty.add-button", action: {})
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, NomaSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Project")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("create.project.close.accessibility-label"))
                }
            }
        }
    }
}
