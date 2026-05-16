import SwiftUI

enum SignInWithAppleGlassButtonLayout {
    static let verticalPadding: NomaMetric.Value = NomaSpacing.authButtonVertical
}

struct SignInWithAppleGlassButtonState: Equatable {
    let isLoading: Bool

    var showsProgressSpinner: Bool { isLoading }
    var allowsInteraction: Bool { !isLoading }
    var usesBlurReplaceTransition: Bool { isLoading }
    var preservesLabelLayout: Bool { true }
}

struct SignInWithAppleGlassButton: View {
    let isLoading: Bool
    let action: () -> Void

    private var state: SignInWithAppleGlassButtonState {
        SignInWithAppleGlassButtonState(isLoading: isLoading)
    }

    init(
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            content
            .font(.title3)
            .foregroundStyle(Color(.systemBackground))
            .frame(maxWidth: .infinity)
            .padding(.vertical, SignInWithAppleGlassButtonLayout.verticalPadding)
            .animation(.smooth, value: isLoading)
        }
        .disabled(!state.allowsInteraction)
        .tint(.primary)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            buttonLabel
                .hidden()
                .accessibilityHidden(true)

            if state.showsProgressSpinner {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color(.systemBackground))
                    .transition(.blurReplace)
            } else {
                buttonLabel
                    .transition(.blurReplace)
            }
        }
    }

    private var buttonLabel: some View {
        Label {
            Text("auth.apple.button.title")
        } icon: {
            Image(systemName: "apple.logo")
                .padding(.trailing, NomaSpacing.sm)
        }
    }
}
