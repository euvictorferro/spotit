//
//  Spot_ItApp.swift
//  Spot It
//
//  Created by Victor Ferro on 8/27/26.
//

import SwiftUI

@main
struct Spot_ItApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .task { await authService.start() }
        }
    }
}
