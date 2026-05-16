import SwiftUI

struct RootView: View {
    @Environment(AuthStateManager.self) private var authState
    @Environment(SubscriptionStateManager.self) private var subscriptionState

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
                SubscriptionGateView()
            }
        }
        .task {
            authState.start()
        }
        .onChange(of: authState.phase) { _, phase in
            guard phase != .signedIn else { return }
            subscriptionState.reset()
        }
    }

    private var loadingView: some View {
        ProgressView()
            .tint(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.primaryBackground)
    }
}

#Preview {
    @Previewable @State var authState = AuthStateManager(
        authClient: UnconfiguredAuthClient(error: SupabaseConfigurationError.missingPublishableKey)
    )
    @Previewable @State var subscriptionState = SubscriptionStateManager(
        entitlementClient: StaticFreeEntitlementClient(),
        storeKitClient: StoreKit2Client(productIDs: [])
    )

    RootView()
        .environment(authState)
        .environment(subscriptionState)
}
