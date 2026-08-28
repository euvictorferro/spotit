import SwiftUI

/// Aberta ao tocar num card de Set — lista todos os carros daquela marca
/// na wallet do usuário.
struct SetDetailView: View {
    let brand: String
    let info: CarBrandInfo
    let items: [WalletItem]
    @State private var detailItem: WalletItem?

    private var totalValue: Double {
        items.reduce(0) { $0 + $1.valorEstimadoUsd }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(verbatim: "\(items.count) / \(info.knownModels) carros")
                        .font(.title3).fontWeight(.heavy).foregroundStyle(Color.accentColor)
                    Text(totalValue.asDollars)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: Theme.Spacing.md) {
                    ForEach(items) { item in
                        row(item)
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle(brand)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detailItem) { item in
            CarDetailPageView(item: item)
        }
    }

    private func row(_ item: WalletItem) -> some View {
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
                    Text(verbatim: "\(ano)").font(.caption).foregroundStyle(.secondary)
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
        .contentShape(Rectangle())
        .onTapGesture { detailItem = item }
    }
}

#Preview {
    NavigationStack {
        SetDetailView(brand: "Ferrari", info: CarBrandInfo.table["Ferrari"]!, items: [WalletItem.sample[7]])
    }
}
