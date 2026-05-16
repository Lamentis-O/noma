import SwiftUI

enum SignupViewLayout {
    static let edgePadding: NomaMetric.Value = NomaSpacing.xxl
    static let bottomPadding: NomaMetric.Value = NomaSpacing.xxl
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
            Rectangle()
                .fill(.primaryBackground)
                .ignoresSafeArea()

            Text("signup.title")
                .font(.title.weight(.black))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)

            VStack {
                Spacer()

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.textSecondary)
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
