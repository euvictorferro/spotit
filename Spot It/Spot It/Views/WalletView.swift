import SwiftUI

private enum WalletTab: String, CaseIterable {
    case summary = "Summary"
    case all = "All"
    case sets = "Sets"
}

struct WalletView: View {
    @State private var items: [WalletItem] = []
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var tab: WalletTab = .summary
    // Reseta a navegação sempre que a aba fica inativa — sem isso, sair pro
    // detalhe de um Set/carro e trocar de aba deixava a Wallet "presa" lá.
    @State private var path = NavigationPath()

    var total: Double {
        items.reduce(0) { $0 + $1.valorEstimadoUsd }
    }

    private var brandCount: Int {
        Set(items.map { CarBrandInfo.brand(for: $0.modelo) }).count
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    tabPicker

                    if items.isEmpty && loadFailed {
                        EmptyStateView(icon: "wifi.slash", message: "Não deu pra carregar sua Wallet agora. Puxe pra atualizar.")
                            .padding(.top, Theme.Spacing.lg)
                    } else if items.isEmpty && !isLoading {
                        EmptyStateView(icon: "car.fill", message: "Sua Wallet está vazia. Tira uma foto de um carro raro pra começar sua coleção.")
                            .padding(.top, Theme.Spacing.lg)
                    } else {
                        switch tab {
                        case .summary:
                            WalletSummaryView(items: items)
                        case .all:
                            WalletAllView(items: $items)
                        case .sets:
                            WalletSetsView(items: items)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(AppGradientBackground())
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
            .toolbarBackground(.hidden, for: .navigationBar)
            .task { await load() }
            .refreshable { await load() }
            .overlay {
                if isLoading && items.isEmpty {
                    WheelLoadingView(size: 44)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { path = NavigationPath() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(total.asDollars)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
            Text("Valor da Coleção (USD)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: Theme.Spacing.md) {
                statBlock(value: "\(items.count)", label: "Carro\(items.count == 1 ? "" : "s")")
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 1, height: 32)
                statBlock(value: "\(brandCount)", label: "Marca\(brandCount == 1 ? "" : "s")")
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topTrailing) {
            // Enfeite puramente decorativo — roda em wireframe quase
            // transparente, sangrando pra fora da tela no canto superior
            // direito, no mesmo espírito do globo em apps de catalogação.
            Image("WalletWheelDecor")
                .resizable()
                .scaledToFit()
                .frame(width: 260, height: 260)
                .opacity(0.18)
                .offset(x: 70, y: -40)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(.system(.title3, design: .rounded, weight: .bold))
            Text(label).font(.subheadline).foregroundStyle(.secondary)
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
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(tab == option ? Color.white : .clear, in: Capsule())
                        .foregroundStyle(tab == option ? .black : .white.opacity(0.8))
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func load() async {
        isLoading = true
        loadFailed = false
        do {
            items = try await SupabaseService.fetchWalletItems()
        } catch {
            loadFailed = true
        }
        isLoading = false
    }
}
