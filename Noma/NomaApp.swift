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
    @State private var onDeviceFoundationModel = OnDeviceFoundationModelService()
    @State private var dailyTaskNotifications = DailyTaskNotificationScheduler()
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
                .environment(onDeviceFoundationModel)
                .environment(dailyTaskNotifications)
                .environment(dailyTaskGroups)
                .onChange(of: authState.storageUserID, initial: true) { _, userID in
                    dailyTaskGroups.switchUserID(userID)
                }
        }
    }
}
