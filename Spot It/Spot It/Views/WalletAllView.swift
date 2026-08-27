import SwiftUI

enum WalletSortOption: String, CaseIterable, Identifiable {
    case priceHighToLow = "Preço: Maior pro Menor"
    case priceLowToHigh = "Preço: Menor pro Maior"
    case yearNewestFirst = "Ano: Mais Novo Primeiro"
    case yearOldestFirst = "Ano: Mais Antigo Primeiro"
    case rarityHighToLow = "Raridade: Maior pro Menor"
    case rarityLowToHigh = "Raridade: Menor pro Maior"
    case addedNewestFirst = "Adicionado: Mais Recente"
    case addedOldestFirst = "Adicionado: Mais Antigo"

    var id: String { rawValue }
}

struct WalletAllView: View {
    let items: [WalletItem]

    @State private var sort: WalletSortOption = .addedNewestFirst
    @State private var showFilter = false
    @State private var selectedBrand: String? // nil = todas
    @State private var selectedRarityTiers: Set<Int> = [] // 1=comum..4=lendário

    @State private var isSelecting = false
    @State private var selectedIDs: Set<UUID> = []

    private var brands: [String] {
        Array(Set(items.map { CarBrandInfo.brand(for: $0.modelo) })).sorted()
    }

    private func tier(for raridade: Int) -> Int {
        switch raridade {
        case ...3: return 1
        case 4...6: return 2
        case 7...8: return 3
        default: return 4
        }
    }

    private var filteredAndSorted: [WalletItem] {
        var result = items
        if let selectedBrand {
            result = result.filter { CarBrandInfo.brand(for: $0.modelo) == selectedBrand }
        }
        if !selectedRarityTiers.isEmpty {
            result = result.filter { selectedRarityTiers.contains(tier(for: $0.raridade)) }
        }
        switch sort {
        case .priceHighToLow: result.sort { $0.valorEstimadoUsd > $1.valorEstimadoUsd }
        case .priceLowToHigh: result.sort { $0.valorEstimadoUsd < $1.valorEstimadoUsd }
        case .yearNewestFirst: result.sort { ($0.ano ?? 0) > ($1.ano ?? 0) }
        case .yearOldestFirst: result.sort { ($0.ano ?? 0) < ($1.ano ?? 0) }
        case .rarityHighToLow: result.sort { $0.raridade > $1.raridade }
        case .rarityLowToHigh: result.sort { $0.raridade < $1.raridade }
        case .addedNewestFirst: result.sort { $0.createdAt > $1.createdAt }
        case .addedOldestFirst: result.sort { $0.createdAt < $1.createdAt }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            toolbarRow

            if isSelecting {
                selectionHeader
            }

            VStack(spacing: Theme.Spacing.md) {
                ForEach(filteredAndSorted) { item in
                    row(item)
                }
            }

            if isSelecting {
                selectionActionBar
            }
        }
        .sheet(isPresented: $showFilter) {
            WalletFilterSheet(
                brands: brands,
                selectedBrand: $selectedBrand,
                selectedRarityTiers: $selectedRarityTiers,
                resultCount: filteredAndSorted.count
            )
        }
    }

    private var toolbarRow: some View {
        HStack {
            Button {
                showFilter = true
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease")
            }

            Menu {
                Picker("Ordenar", selection: $sort) {
                    ForEach(WalletSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }

            Spacer()

            Button {
                isSelecting.toggle()
                selectedIDs.removeAll()
            } label: {
                Image(systemName: isSelecting ? "checklist.checked" : "checklist")
            }
        }
        .font(.subheadline)
        .foregroundStyle(isSelecting ? Color.accentColor : .primary)
    }

    private var selectionHeader: some View {
        HStack {
            Button {
                if selectedIDs.count == filteredAndSorted.count {
                    selectedIDs.removeAll()
                } else {
                    selectedIDs = Set(filteredAndSorted.map(\.id))
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedIDs.count == filteredAndSorted.count && !filteredAndSorted.isEmpty ? "checkmark.square.fill" : "square")
                    Text("Selecionar Tudo")
                }
            }
            .foregroundStyle(Color.accentColor)

            Spacer()

            Button("Cancelar") {
                isSelecting = false
                selectedIDs.removeAll()
            }
        }
        .font(.subheadline)
    }

    private var selectionActionBar: some View {
        HStack {
            selectionAction(icon: "trash", label: "Excluir")
            Spacer()
            selectionAction(icon: "folder", label: "Mover")
            Spacer()
            selectionAction(icon: "square.and.arrow.up", label: "Exportar")
        }
        .padding(.top, Theme.Spacing.sm)
    }

    private func selectionAction(icon: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
            Text(label).font(.caption2)
        }
        .foregroundStyle(selectedIDs.isEmpty ? .tertiary : .primary)
        .opacity(selectedIDs.isEmpty ? 0.5 : 1)
    }

    private func row(_ item: WalletItem) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            if isSelecting {
                Image(systemName: selectedIDs.contains(item.id) ? "checkmark.square.fill" : "square")
                    .foregroundStyle(selectedIDs.contains(item.id) ? Color.accentColor : .secondary)
                    .onTapGesture { toggle(item.id) }
            }

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
        .onTapGesture { if isSelecting { toggle(item.id) } }
    }

    private func toggle(_ id: UUID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }
}

#Preview {
    ScrollView { WalletAllView(items: WalletItem.sample).padding() }
}
