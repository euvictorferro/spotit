import SwiftUI

struct WalletView: View {
    @State private var items: [WalletItem] = []
    @State private var isLoading = true

    var total: Double {
        items.reduce(0) { $0 + $1.valorEstimadoUsd }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    Text("$\(total, specifier: "%.0f")")
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(item.modelo).font(.headline)
                            Text("$\(item.valorEstimadoUsd, specifier: "%.0f") · Raridade \(item.raridade)/10")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .rarityCard(item.raridade)
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Wallet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: MapView(scope: .wallet)) {
                        Image(systemName: "map")
                    }
                }
            }
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
