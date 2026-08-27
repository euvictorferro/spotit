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
                    Text(total, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(items) { item in
                        walletRow(item)
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

    private func walletRow(_ item: WalletItem) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Theme.rarityColor(item.raridade).opacity(0.55), Theme.rarityColor(item.raridade).opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "car.side.fill").foregroundStyle(Theme.rarityColor(item.raridade)))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.modelo).font(.subheadline).fontWeight(.semibold)
                if let ano = item.ano {
                    Text("\(ano)").font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.valorEstimadoUsd, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                Text("Raridade \(item.raridade)/10")
                    .font(.caption2)
                    .foregroundStyle(Theme.rarityColor(item.raridade))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rarityCard(item.raridade)
    }

    private func load() async {
        isLoading = true
        let fetched = (try? await SupabaseService.fetchWalletItems()) ?? []
        // Sem itens reais salvos ainda — mostra exemplos pra visualizar a Wallet cheia.
        items = fetched.isEmpty ? WalletItem.sample : fetched
        isLoading = false
    }
}
