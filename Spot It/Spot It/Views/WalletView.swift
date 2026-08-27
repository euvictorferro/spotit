import SwiftUI

private enum WalletTab: String, CaseIterable {
    case summary = "Summary"
    case all = "All"
    case sets = "Sets"
}

struct WalletView: View {
    @State private var items: [WalletItem] = []
    @State private var isLoading = true
    @State private var tab: WalletTab = .summary

    var total: Double {
        items.reduce(0) { $0 + $1.valorEstimadoUsd }
    }

    private var brandCount: Int {
        Set(items.map { CarBrandInfo.brand(for: $0.modelo) }).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    tabPicker

                    switch tab {
                    case .summary:
                        WalletSummaryView(items: items)
                    case .all:
                        allTab
                    case .sets:
                        WalletSetsView(items: items)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(total.asDollars)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
            Text("Valor da Coleção (USD)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(items.count)").font(.headline)
                    Text("Carro\(items.count == 1 ? "" : "s")").font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(brandCount)").font(.headline)
                    Text("Marca\(brandCount == 1 ? "" : "s")").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 4) {
            ForEach(WalletTab.allCases, id: \.self) { option in
                Button {
                    tab = option
                } label: {
                    Text(option.rawValue)
                        .font(.subheadline)
                        .fontWeight(tab == option ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(tab == option ? Color(.systemBackground) : .clear, in: Capsule())
                        .foregroundStyle(tab == option ? .primary : .secondary)
                }
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground), in: Capsule())
    }

    private var allTab: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(items) { item in
                walletRow(item)
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
                Text(item.valorEstimadoUsd.asDollars)
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
