import SwiftUI

struct CreateProjectEmptyState {
    let systemImage: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let cta: HintCTA?

    static let placeholder = CreateProjectEmptyState(
        systemImage: "tray.full",
        title: "create.project.empty.title",
        subtitle: "create.project.empty.subtitle",
        cta: nil
    )
}

struct CreateSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let emptyState = CreateProjectEmptyState.placeholder

    var body: some View {
        NavigationStack {
            VStack {
                Spacer(minLength: 0)

                HintView(
                    systemImage: emptyState.systemImage,
                    title: emptyState.title,
                    subtitle: emptyState.subtitle,
                    cta: emptyState.cta
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
