import SwiftUI

enum SignupViewLayout {
    static let edgePadding: NomaMetric.Value = NomaSpacing.xl
    static let bottomPadding: NomaMetric.Value = NomaSpacing.xl
}

struct SignupView: View {
    let isLoading: Bool
    let errorMessage: String?
    let signInWithApple: () -> Void

    init(
        isLoading: Bool = false,
        errorMessage: String? = nil,
        signInWithApple: @escaping () -> Void
    ) {
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.signInWithApple = signInWithApple
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Text("signup.title")
                .font(.title.weight(.black))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)

            VStack {
                Spacer()

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SignupViewLayout.edgePadding)
                        .transition(.blurReplace)
                }

                SignInWithAppleGlassButton(
                    isLoading: isLoading,
                    action: signInWithApple
                )
                    .padding(.horizontal, SignupViewLayout.edgePadding)
                    .padding(.bottom, SignupViewLayout.bottomPadding)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

#Preview {
    SignupView {}
}
