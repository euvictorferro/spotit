import SwiftUI
import Photos

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
    @Binding var items: [WalletItem]

    @State private var sort: WalletSortOption = .addedNewestFirst
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showFilter = false
    @State private var selectedCountry: String? // nil = todos
    @State private var selectedEdition: String? // nil = todas
    @State private var selectedBrand: String? // nil = todas
    @State private var selectedRarityTiers: Set<Int> = [] // 1=comum..4=lendário
    @State private var yearLow: Double
    @State private var yearHigh: Double
    @State private var priceLow: Double
    @State private var priceHigh: Double

    @State private var isSelecting = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var detailItem: WalletItem?
    @State private var isExporting = false
    @State private var exportMessage: String?

    init(items: Binding<[WalletItem]>) {
        self._items = items
        let years = items.wrappedValue.compactMap { $0.ano }.map(Double.init)
        let prices = items.wrappedValue.map(\.valorEstimadoUsd)
        _yearLow = State(initialValue: years.min() ?? 1990)
        _yearHigh = State(initialValue: years.max() ?? 2026)
        _priceLow = State(initialValue: prices.min() ?? 0)
        _priceHigh = State(initialValue: prices.max() ?? 1)
    }

    private var brands: [String] {
        Array(Set(items.map { CarBrandInfo.brand(for: $0.modelo) })).sorted()
    }

    private var countries: [String] {
        Array(Set(items.compactMap { CarBrandInfo.info(for: $0.modelo)?.country })).sorted()
    }

    private var editions: [String] {
        Array(Set(items.compactMap(\.edicaoEspecial))).sorted()
    }

    private var yearBounds: ClosedRange<Double> {
        let years = items.compactMap { $0.ano }.map(Double.init)
        guard let min = years.min(), let max = years.max(), min < max else { return 1990...2026 }
        return min...max
    }

    private var priceBounds: ClosedRange<Double> {
        let prices = items.map(\.valorEstimadoUsd)
        guard let min = prices.min(), let max = prices.max(), min < max else { return 0...1 }
        return min...max
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
        if let selectedCountry {
            result = result.filter { CarBrandInfo.info(for: $0.modelo)?.country == selectedCountry }
        }
        if let selectedEdition {
            result = result.filter { $0.edicaoEspecial == selectedEdition }
        }
        if let selectedBrand {
            result = result.filter { CarBrandInfo.brand(for: $0.modelo) == selectedBrand }
        }
        if !selectedRarityTiers.isEmpty {
            result = result.filter { selectedRarityTiers.contains(tier(for: $0.raridade)) }
        }
        result = result.filter { item in
            guard let ano = item.ano else { return true }
            return Double(ano) >= yearLow && Double(ano) <= yearHigh
        }
        result = result.filter { $0.valorEstimadoUsd >= priceLow && $0.valorEstimadoUsd <= priceHigh }
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
                selectionActionBar
            }

            if let exportMessage {
                Text(exportMessage).font(.caption).foregroundStyle(.secondary)
            }

            VStack(spacing: Theme.Spacing.md) {
                ForEach(filteredAndSorted) { item in
                    row(item)
                }
            }
        }
        .sheet(isPresented: $showFilter) {
            WalletFilterSheet(
                countries: countries,
                selectedCountry: $selectedCountry,
                editions: editions,
                selectedEdition: $selectedEdition,
                brands: brands,
                selectedBrand: $selectedBrand,
                selectedRarityTiers: $selectedRarityTiers,
                yearBounds: yearBounds,
                yearLow: $yearLow,
                yearHigh: $yearHigh,
                priceBounds: priceBounds,
                priceLow: $priceLow,
                priceHigh: $priceHigh,
                items: items,
                resultCount: filteredAndSorted.count
            )
        }
        .fullScreenCover(item: $detailItem) { item in
            CarDetailPageView(item: item)
        }
        .confirmationDialog(
            "Você tem certeza que quer deletar esses carros?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Deletar \(selectedIDs.count) carro\(selectedIDs.count == 1 ? "" : "s")", role: .destructive) {
                Task { await deleteSelected() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Essas fotos não estarão salvas e você não conseguirá recuperar depois.")
        }
    }

    private func deleteSelected() async {
        isDeleting = true
        let idsToDelete = selectedIDs
        try? await SupabaseService.deleteWalletItems(ids: Array(idsToDelete))
        items.removeAll { idsToDelete.contains($0.id) }
        selectedIDs.removeAll()
        isSelecting = false
        isDeleting = false
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
            selectionAction(icon: "trash", label: "Excluir") {
                showDeleteConfirm = true
            }
            Spacer()
            selectionAction(icon: isExporting ? "hourglass" : "square.and.arrow.down", label: "Exportar") {
                Task { await exportSelected() }
            }
            .disabled(selectedIDs.isEmpty || isExporting)
        }
        .padding(.top, Theme.Spacing.sm)
    }

    /// Baixa a foto de cada carro selecionado e salva na galeria do usuário
    /// (Fotos do iOS) — pede permissão de "adicionar fotos" na primeira vez.
    private func exportSelected() async {
        isExporting = true
        exportMessage = nil
        let urls = items.filter { selectedIDs.contains($0.id) && !$0.fotoUrl.isEmpty }.compactMap { URL(string: $0.fotoUrl) }
        guard !urls.isEmpty else {
            exportMessage = "Nenhuma foto disponível pra exportar."
            isExporting = false
            return
        }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            exportMessage = "Sem permissão pra salvar na galeria. Verifique em Ajustes."
            isExporting = false
            return
        }
        var saved = 0
        for url in urls {
            guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { continue }
            let ok = (try? await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) != nil
            if ok { saved += 1 }
        }
        exportMessage = saved > 0 ? "\(saved) foto\(saved == 1 ? "" : "s") salva\(saved == 1 ? "" : "s") na galeria." : "Não foi possível exportar as fotos."
        isExporting = false
    }

    private func selectionAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(label).font(.caption2)
            }
            .foregroundStyle(selectedIDs.isEmpty ? .tertiary : .primary)
            .opacity(selectedIDs.isEmpty ? 0.5 : 1)
        }
        .disabled(selectedIDs.isEmpty)
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
        .onTapGesture {
            if isSelecting {
                toggle(item.id)
            } else {
                detailItem = item
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }
}

#Preview {
    ScrollView { WalletAllView(items: .constant(WalletItem.sample)).padding() }
}
