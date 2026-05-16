//
//  ContentView.swift
//  Noma
//
//  Created by Elias Papavlassopoulos on 15.05.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
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

    ContentView()
        .environment(authState)
        .environment(subscriptionState)
}
