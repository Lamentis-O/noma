import SwiftUI

struct SubscriptionGateView: View {
    @Environment(SubscriptionStateManager.self) private var subscriptionState

    var body: some View {
        Group {
            switch subscriptionState.phase {
            case .loading:
                loadingView
            case .free, .pro:
                HomeView()
            case .expired, .unavailable:
                PaywallView()
            }
        }
        .task {
            subscriptionState.start()
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
