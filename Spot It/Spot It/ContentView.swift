//
//  ContentView.swift
//  Spot It
//
//  Created by Victor Ferro on 8/27/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem { Label("Captura", systemImage: "camera") }

            WalletView()
                .tabItem { Label("Wallet", systemImage: "wallet.pass") }
        }
    }
}

#Preview {
    ContentView()
}
