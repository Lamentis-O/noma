import SwiftUI

struct UnlockMoreSheet: View {
    let close: () -> Void

    var body: some View {
        NavigationStack {
            Rectangle()
                .fill(.primaryBackground)
                .ignoresSafeArea(.container)
                .navigationTitle(LocalizedStringKey("create.unlock-more.sheet.title"))
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    CloseToolbarButton(
                        accessibilityLabelKey: "create.unlock-more.close.accessibility-label",
                        action: close
                    )
                }
        }
    }
}
