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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authState)
        }
    }
}
