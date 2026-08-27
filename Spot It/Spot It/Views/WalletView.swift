import SwiftUI

struct WalletView: View {
    @State private var items: [WalletItem] = []
    @State private var isLoading = true

    var total: Double {
        items.reduce(0) { $0 + $1.valorEstimadoUsd }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Total: $\(total, specifier: "%.0f")")
                        .font(.title2).bold()
                }

                ForEach(items) { item in
                    VStack(alignment: .leading) {
                        Text(item.modelo).font(.headline)
                        Text("$\(item.valorEstimadoUsd, specifier: "%.0f") · Raridade \(item.raridade)/10")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Wallet")
            .task { await load() }
            .refreshable { await load() }
            .overlay {
                if isLoading && items.isEmpty {
                    ProgressView()
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        items = (try? await SupabaseService.fetchWalletItems()) ?? []
        isLoading = false
    }
}
