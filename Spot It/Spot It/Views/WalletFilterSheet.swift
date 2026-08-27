import SwiftUI

private let rarityTiers: [(id: Int, label: String)] = [
    (1, "Comum"), (2, "Incomum"), (3, "Raro"), (4, "Lendário"),
]

struct WalletFilterSheet: View {
    let countries: [String]
    @Binding var selectedCountry: String?

    let editions: [String]
    @Binding var selectedEdition: String?

    let brands: [String]
    @Binding var selectedBrand: String?

    @Binding var selectedRarityTiers: Set<Int>

    let yearBounds: ClosedRange<Double>
    @Binding var yearLow: Double
    @Binding var yearHigh: Double

    let priceBounds: ClosedRange<Double>
    @Binding var priceLow: Double
    @Binding var priceHigh: Double

    let items: [WalletItem]
    let resultCount: Int

    @Environment(\.dismiss) private var dismiss

    private func flag(for country: String) -> String {
        CarBrandInfo.table.values.first { $0.country == country }?.flag ?? "🏳️"
    }

    private var priceHistogram: [Int] {
        histogram(for: items.map(\.valorEstimadoUsd), bounds: priceBounds, buckets: 12)
    }

    private var yearHistogram: [Int] {
        histogram(for: items.compactMap { $0.ano }.map(Double.init), bounds: yearBounds, buckets: 12)
    }

    private func histogram(for values: [Double], bounds: ClosedRange<Double>, buckets: Int) -> [Int] {
        guard bounds.upperBound > bounds.lowerBound else { return [] }
        var counts = [Int](repeating: 0, count: buckets)
        let width = (bounds.upperBound - bounds.lowerBound) / Double(buckets)
        for value in values {
            let index = min(buckets - 1, max(0, Int((value - bounds.lowerBound) / width)))
            counts[index] += 1
        }
        return counts
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    section("País") {
                        FlowChips {
                            chip("Todos", icon: "globe", isSelected: selectedCountry == nil) { selectedCountry = nil }
                            ForEach(countries, id: \.self) { country in
                                chip(country, emoji: flag(for: country), isSelected: selectedCountry == country) { selectedCountry = country }
                            }
                        }
                    }

                    if !editions.isEmpty {
                        section("Set") {
                            FlowChips {
                                chip("Todas", isSelected: selectedEdition == nil) { selectedEdition = nil }
                                ForEach(editions, id: \.self) { edition in
                                    chip(edition, isSelected: selectedEdition == edition) { selectedEdition = edition }
                                }
                            }
                        }
                    }

                    section("Marca") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            gridChip("Todas", isSelected: selectedBrand == nil) { selectedBrand = nil }
                            ForEach(brands, id: \.self) { brand in
                                gridChip(brand, isSelected: selectedBrand == brand) { selectedBrand = brand }
                            }
                        }
                    }

                    section("Raridade") {
                        FlowChips {
                            ForEach(rarityTiers, id: \.id) { tier in
                                chip(tier.label, isSelected: selectedRarityTiers.contains(tier.id)) {
                                    if selectedRarityTiers.contains(tier.id) {
                                        selectedRarityTiers.remove(tier.id)
                                    } else {
                                        selectedRarityTiers.insert(tier.id)
                                    }
                                }
                            }
                        }
                    }

                    section("Ano do Carro") {
                        RangeSliderView(bounds: yearBounds, low: $yearLow, high: $yearHigh, histogram: yearHistogram) {
                            String(format: "%.0f", $0)
                        }
                    }

                    section("Preço") {
                        RangeSliderView(bounds: priceBounds, low: $priceLow, high: $priceHigh, histogram: priceHistogram) {
                            $0.asDollars
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Filtro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: Theme.Spacing.md) {
                    Button("Limpar Tudo") {
                        selectedCountry = nil
                        selectedEdition = nil
                        selectedBrand = nil
                        selectedRarityTiers.removeAll()
                        yearLow = yearBounds.lowerBound
                        yearHigh = yearBounds.upperBound
                        priceLow = priceBounds.lowerBound
                        priceHigh = priceBounds.upperBound
                    }
                    .foregroundStyle(.secondary)

                    Button {
                        dismiss()
                    } label: {
                        Text("Mostrar \(resultCount) Carro\(resultCount == 1 ? "" : "s")")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(Theme.Spacing.md)
                .background(.bar)
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title).font(.headline)
            content()
        }
    }

    private func chip(_ label: String, icon: String? = nil, emoji: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon) }
                if let emoji { FlagBadge(flag: emoji).frame(width: 16, height: 16) }
                Text(label)
            }
            .font(.subheadline)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }

    /// Chip de largura total pra grid de 2 colunas — evita quebrar nome de marca em 2 linhas.
    private func gridChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

/// Layout tipo "flow" simples (quebra linha) pra chips — LazyVGrid adaptativo
/// já resolve sem precisar de um layout customizado.
private struct FlowChips<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
            content
        }
    }
}

#Preview {
    WalletFilterSheet(
        countries: ["Itália", "Alemanha"],
        selectedCountry: .constant(nil),
        editions: ["Mansory"],
        selectedEdition: .constant(nil),
        brands: ["Ferrari", "Porsche"],
        selectedBrand: .constant(nil),
        selectedRarityTiers: .constant([]),
        yearBounds: 1996...2023,
        yearLow: .constant(1996),
        yearHigh: .constant(2023),
        priceBounds: 45_000...3_000_000,
        priceLow: .constant(45_000),
        priceHigh: .constant(3_000_000),
        items: WalletItem.sample,
        resultCount: 20
    )
}
