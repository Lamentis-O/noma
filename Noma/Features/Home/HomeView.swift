import SwiftUI

private enum HomeRoute: Hashable {
    case create(dayID: String)
}

struct HomeView: View {
    @Environment(DailyTaskGroupStore.self) private var dailyTaskGroups
    @State private var path: [HomeRoute] = []

    var body: some View {
        GeometryReader { proxy in
            NavigationStack(path: $path) {
                ZStack {
                    Rectangle()
                        .fill(.primaryBackground)
                        .ignoresSafeArea()

                    ScrollView {
                        dailyGroupsList
                    }
                    .scrollIndicators(.hidden)
                }
                .safeAreaBar(edge: .bottom, alignment: .trailing, spacing: 0) {
                    createButton
                        .padding(.trailing, NomaSpacing.xxl)
                        .padding(.bottom, max(0, NomaSpacing.xxl - proxy.safeAreaInsets.bottom))
                        .offset(y: max(0, proxy.safeAreaInsets.bottom - NomaSpacing.xxl))
                }
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case let .create(dayID):
                        CreateView(dayID: dayID)
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
            path.append(.create(dayID: dailyTaskGroups.todayID()))
        }
    }

    private var dailyGroupsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !dailyTaskGroups.groups.isEmpty {
                SectionHeader(DailyTaskGroupsSection.headerTitleKey)

                VStack(alignment: .leading, spacing: NomaSpacing.xl) {
                    ForEach(dailyTaskGroups.summaries()) { summary in
                        Button {
                            path.append(.create(dayID: summary.id))
                        } label: {
                            DailyTaskGroupRow(summary: summary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, NomaSpacing.xl)
        .padding(.top, NomaSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
