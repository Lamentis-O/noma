//
//  NomaApp.swift
//  Noma
//
//  Created by Elias Papavlassopoulos on 15.05.26.
//

import SwiftUI

@main
struct NomaApp: App {
    @State private var authState = AuthStateManager()
    @State private var subscriptionTier = SubscriptionTierManager()
    #if DEBUG
    @State private var dailyTaskGroups = DailyTaskGroupStore(usesMockData: true)
    #else
    @State private var dailyTaskGroups = DailyTaskGroupStore()
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authState)
                .environment(subscriptionTier)
                .environment(dailyTaskGroups)
                .onChange(of: authState.storageUserID, initial: true) { _, userID in
                    dailyTaskGroups.switchUserID(userID)
                }
        }
    }
}
