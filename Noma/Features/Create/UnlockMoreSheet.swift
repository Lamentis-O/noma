import SwiftUI

struct UnlockMoreSheet: View {
    let close: () -> Void

    var body: some View {
        EmptyNavigationSheet(
            titleKey: "create.unlock-more.sheet.title",
            closeAccessibilityLabelKey: "create.unlock-more.close.accessibility-label",
            close: close
        )
    }
}
