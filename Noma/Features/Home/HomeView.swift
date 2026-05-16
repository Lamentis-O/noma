import SwiftUI

private enum HomeRoute: Hashable {
    case create
}

struct HomeView: View {
    @State private var path: [HomeRoute] = []

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
                    .safeAreaBar(edge: .top) {
                        HomeTopBar()
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
