import SwiftUI

private let rarityTiers: [(id: Int, label: String)] = [
    (1, "Comum"), (2, "Incomum"), (3, "Raro"), (4, "Lendário"),
]

struct WalletFilterSheet: View {
    let brands: [String]
    @Binding var selectedBrand: String?
    @Binding var selectedRarityTiers: Set<Int>
    let resultCount: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    section("Marca") {
                        FlowChips {
                            chip("Todas", isSelected: selectedBrand == nil) { selectedBrand = nil }
                            ForEach(brands, id: \.self) { brand in
                                chip(brand, isSelected: selectedBrand == brand) { selectedBrand = brand }
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
                        selectedBrand = nil
                        selectedRarityTiers.removeAll()
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

    private func chip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, Theme.Spacing.md)
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
    WalletFilterSheet(brands: ["Ferrari", "Porsche"], selectedBrand: .constant(nil), selectedRarityTiers: .constant([]), resultCount: 20)
}
