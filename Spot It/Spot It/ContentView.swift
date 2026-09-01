//
//  ContentView.swift
//  Spot It
//
//  Created by Victor Ferro on 8/27/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var showCapture = false
    @StateObject private var captureButtonVisibility = CaptureButtonVisibility()
    @StateObject private var tabSelection = TabSelection()

    var body: some View {
        Group {
            if !authService.isReady {
                ZStack {
                    AppGradientBackground()
                    WheelLoadingView(size: 56)
                }
            } else if authService.session == nil {
                WelcomeView()
            } else if authService.profile == nil {
                OnboardingView()
            } else {
                mainTabs
            }
        }
        // Sem isso, sair do app com o "+" escondido (ex.: dentro de uma
        // conversa de DM) deixava ele escondido pra sempre na próxima
        // sessão/login, mesmo pra um usuário diferente.
        .onChange(of: authService.session == nil) { _, isSignedOut in
            if isSignedOut { captureButtonVisibility.isHidden = false }
        }
    }

    private var mainTabs: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $tabSelection.selected) {
                FeedView()
                    .tabItem { Image(systemName: "house") }
                    .tag(MainTab.feed)

                DMView()
                    .tabItem { Image(systemName: "message") }
                    .tag(MainTab.dm)

                SearchUsersView()
                    .tabItem { Image(systemName: "magnifyingglass") }
                    .tag(MainTab.search)

                WalletView()
                    .tabItem { Image(systemName: "wallet.pass") }
                    .tag(MainTab.wallet)

                ProfileView()
                    .tabItem { Image(systemName: "person.circle") }
                    .tag(MainTab.profile)
            }
            .environmentObject(captureButtonVisibility)
            .environmentObject(tabSelection)

            if !captureButtonVisibility.isHidden {
                Button {
                    showCapture = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.accentColor))
                        .shadow(radius: 4, y: 2)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 70)
            }
        }
        .fullScreenCover(isPresented: $showCapture) {
            CaptureView()
        }
    }
}

#Preview {
    ContentView().environmentObject(AuthService())
}
