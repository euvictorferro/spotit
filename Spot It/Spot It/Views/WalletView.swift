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
                        WalletAllView(items: items)
                    case .sets:
                        WalletSetsView(items: items)
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Spot It").font(.headline)
                }
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

    private func load() async {
        isLoading = true
        let fetched = (try? await SupabaseService.fetchWalletItems()) ?? []
        // Sem itens reais salvos ainda — mostra exemplos pra visualizar a Wallet cheia.
        items = fetched.isEmpty ? WalletItem.sample : fetched
        isLoading = false
    }
}
