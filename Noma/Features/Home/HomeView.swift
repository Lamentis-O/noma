import SwiftUI

private enum HomeRoute: Hashable {
    case create
}

struct HomeView: View {
    @Environment(AuthStateManager.self) private var authState
    @Environment(SubscriptionStateManager.self) private var subscriptionState
    @State private var path: [HomeRoute] = []
    @State private var isShowingProSheet = false

    var body: some View {
        GeometryReader { proxy in
            NavigationStack(path: $path) {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .safeAreaBar(edge: .bottom, alignment: .trailing, spacing: 0) {
                        createButton
                            .padding(.trailing, NomaSpacing.xl)
                            .padding(.bottom, max(0, NomaSpacing.xl - proxy.safeAreaInsets.bottom))
                            .offset(y: max(0, proxy.safeAreaInsets.bottom - NomaSpacing.xl))
                    }
                    .navigationDestination(for: HomeRoute.self) { route in
                        switch route {
                        case .create:
                            CreateView()
                        }
                    }
                    .navigationTitle("Noma")
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .sheet(isPresented: $isShowingProSheet) {
                        PaywallView()
                            .presentationDetents([.large])
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            if subscriptionState.phase.showsProEntryPoint {
                                Button {
                                    isShowingProSheet = true
                                } label: {
                                    Image(systemName: "crown")
                                }
                                .accessibilityLabel(Text("subscription.pro.toolbar.accessibility-label"))
                            }

                            Menu {
                                Button(role: .destructive) {
                                    authState.signOut()
                                } label: {
                                    Label(
                                        "auth.logout.title",
                                        systemImage: "rectangle.portrait.and.arrow.right"
                                    )
                                }
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
            }
        }
    }

    private var createButton: some View {
        PrimaryGlassButton(
            title: "create.button.title",
            systemImage: "square.and.pencil"
        ) {
            path.append(.create)
        }
    }
}
