import SwiftUI

struct RootView: View {
    @Environment(AuthStateManager.self) private var authState

    var body: some View {
        Group {
            switch authState.phase {
            case .loading:
                loadingView
            case .signedOut:
                SignupView(
                    isLoading: authState.isSigningIn,
                    errorMessage: authState.errorMessage
                ) {
                    authState.signInWithApple()
                }
            case .signedIn:
                HomeView()
            }
        }
        .task {
            authState.start()
        }
    }

    private var loadingView: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ProgressView()
                .tint(.primary)
        }
    }
}

#Preview {
    @Previewable @State var authState = AuthStateManager(
        authClient: UnconfiguredAuthClient(error: SupabaseConfigurationError.missingPublishableKey)
    )

    RootView()
        .environment(authState)
}
