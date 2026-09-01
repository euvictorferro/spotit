import SwiftUI

private enum SetSortOption: String, CaseIterable, Identifiable {
    case mostComplete = "Mais Completo Primeiro"
    case leastComplete = "Menos Completo Primeiro"
    case valueHighToLow = "Valor: Maior pro Menor"
    case valueLowToHigh = "Valor: Menor pro Maior"

    var id: String { rawValue }
}

struct WalletSetsView: View {
    let items: [WalletItem]
    @State private var sort: SetSortOption = .mostComplete

    private var sets: [(brand: String, info: CarBrandInfo, items: [WalletItem], totalValue: Double)] {
        // Marcas fora da CarBrandInfo.table (fallback, knownModels: 0) não
        // são mais descartadas — sem isso, um Ferrari registrado do lado de
        // uma Tesla mostrava contagens diferentes entre Sets e Wallet normal.
        let grouped = Dictionary(grouping: items) { CarBrandInfo.brand(for: $0.modelo) }
            .map { brand, items -> (String, CarBrandInfo, [WalletItem], Double) in
                let info = CarBrandInfo.info(forBrand: brand)
                let total = items.reduce(0) { $0 + $1.valorEstimadoUsd }
                return (brand, info, items, total)
            }

        func completion(_ set: (String, CarBrandInfo, [WalletItem], Double)) -> Double {
            Double(set.2.count) / Double(max(1, set.1.knownModels))
        }

        switch sort {
        case .mostComplete:
            return grouped.sorted { completion($0) > completion($1) }
        case .leastComplete:
            return grouped.sorted { completion($0) < completion($1) }
        case .valueHighToLow:
            return grouped.sorted { $0.3 > $1.3 }
        case .valueLowToHigh:
            return grouped.sorted { $0.3 < $1.3 }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Menu {
                Picker("Ordenar", selection: $sort) {
                    ForEach(SetSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Label(sort.rawValue, systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                ForEach(sets, id: \.brand) { set in
                    SetCard(brand: set.brand, info: set.info, items: set.items, totalValue: set.totalValue)
                }
            }
        }
    }
}

#Preview {
    ScrollView { WalletSetsView(items: WalletItem.sample).padding() }
}
