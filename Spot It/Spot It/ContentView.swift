//
//  ContentView.swift
//  Spot It
//
//  Created by Victor Ferro on 8/27/26.
//

import SwiftUI

struct ContentView: View {
    @State private var showCapture = false
    @StateObject private var captureButtonVisibility = CaptureButtonVisibility()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                FeedView()
                    .tabItem { Label("Feed", systemImage: "house") }

                WalletView()
                    .tabItem { Label("Wallet", systemImage: "wallet.pass") }

                DMView()
                    .tabItem { Label("DM", systemImage: "message") }

                ProfileView()
                    .tabItem { Label("Perfil", systemImage: "person.circle") }
            }
            .environmentObject(captureButtonVisibility)

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
                }
                .padding(.trailing, 20)
                .padding(.bottom, 70)
            }
        }
        .sheet(isPresented: $showCapture) {
            CaptureView()
        }
    }
}

#Preview {
    ContentView()
}
