import SwiftUI

struct WalletSetsView: View {
    let items: [WalletItem]

    private var sets: [(brand: String, info: CarBrandInfo, count: Int)] {
        Dictionary(grouping: items) { CarBrandInfo.brand(for: $0.modelo) }
            .compactMap { brand, items -> (String, CarBrandInfo, Int)? in
                guard let info = CarBrandInfo.table[brand] else { return nil }
                return (brand, info, items.count)
            }
            .sorted { $0.2 > $1.2 }
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
            ForEach(sets, id: \.brand) { set in
                SetCard(brand: set.brand, info: set.info, count: set.count)
            }
        }
    }
}

#Preview {
    ScrollView { WalletSetsView(items: WalletItem.sample).padding() }
}
