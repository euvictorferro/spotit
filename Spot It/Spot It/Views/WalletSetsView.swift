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
        let grouped = Dictionary(grouping: items) { CarBrandInfo.brand(for: $0.modelo) }
            .compactMap { brand, items -> (String, CarBrandInfo, [WalletItem], Double)? in
                guard let info = CarBrandInfo.table[brand] else { return nil }
                let total = items.reduce(0) { $0 + $1.valorEstimadoUsd }
                return (brand, info, items, total)
            }

        switch sort {
        case .mostComplete:
            return grouped.sorted { Double($0.2.count) / Double($0.1.knownModels) > Double($1.2.count) / Double($1.1.knownModels) }
        case .leastComplete:
            return grouped.sorted { Double($0.2.count) / Double($0.1.knownModels) < Double($1.2.count) / Double($1.1.knownModels) }
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
