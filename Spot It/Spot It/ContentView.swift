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
                    .tabItem { Image(systemName: "house") }

                DMView()
                    .tabItem { Image(systemName: "message") }

                SearchUsersView()
                    .tabItem { Image(systemName: "magnifyingglass") }

                WalletView()
                    .tabItem { Image(systemName: "wallet.pass") }

                ProfileView()
                    .tabItem { Image(systemName: "person.circle") }
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
    ContentView()
}
