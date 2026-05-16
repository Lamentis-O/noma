import SwiftUI

private enum HomeRoute: Hashable {
    case create(dayID: String)
}

enum HomeViewLayout {
    static let contentTopPadding = NomaSpacing.xl
}

struct HomeView: View {
    @Environment(DailyTaskGroupStore.self) private var dailyTaskGroups
    @Environment(SubscriptionTierManager.self) private var subscriptionTier
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
        VStack(alignment: .leading, spacing: NomaSpacing.xl) {
            if DailyTaskMetricsSectionVisibility.isVisible(for: subscriptionTier.tier) {
                DailyTaskMetricsSection(metrics: dailyTaskGroups.metrics())
            }

            if !dailyTaskGroups.groups.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
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
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, NomaSpacing.xl)
        .padding(.top, HomeViewLayout.contentTopPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
