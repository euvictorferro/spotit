import SwiftUI
import MapKit

struct WalletSummaryView: View {
    let items: [WalletItem]
    @State private var showFeedback = false
    @State private var showFullMap = false

    private var mostExpensive: WalletItem? {
        items.max { $0.valorEstimadoUsd < $1.valorEstimadoUsd }
    }

    private var fastest: WalletItem? {
        items.compactMap { item in item.aceleracao0a100.map { (item, $0) } }
            .min { $0.1 < $1.1 }?.0
    }

    private var rarest: WalletItem? {
        items.max { $0.raridade < $1.raridade }
    }

    private var bestCarPages: [BestCarPage] {
        [
            mostExpensive.map { BestCarPage(item: $0, badge: "Mais Valioso") },
            fastest.map { BestCarPage(item: $0, badge: "Mais Rápido") },
            rarest.map { BestCarPage(item: $0, badge: "Mais Raro") },
        ].compactMap { $0 }
    }

    private var countryBreakdown: [(info: CarBrandInfo, count: Int)] {
        var counts: [String: Int] = [:]
        for item in items {
            let brand = CarBrandInfo.brand(for: item.modelo)
            guard CarBrandInfo.table[brand] != nil else { continue }
            counts[brand, default: 0] += 1
        }
        return counts.compactMap { brand, count in
            CarBrandInfo.table[brand].map { (info: $0, count: count) }
        }
        .reduce(into: [String: (CarBrandInfo, Int)]()) { acc, entry in
            acc[entry.info.country, default: (entry.info, 0)].1 += entry.count
        }
        .values
        .map { (info: $0.0, count: $0.1) }
        .sorted { $0.count > $1.count }
    }

    private var sets: [(brand: String, info: CarBrandInfo, items: [WalletItem])] {
        Dictionary(grouping: items) { CarBrandInfo.brand(for: $0.modelo) }
            .compactMap { brand, items -> (String, CarBrandInfo, [WalletItem])? in
                guard let info = CarBrandInfo.table[brand] else { return nil }
                return (brand, info, items)
            }
            .sorted { $0.2.count > $1.2.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            if !bestCarPages.isEmpty {
                sectionHeader("Seus Melhores Carros")
                BestCarsCarousel(pages: bestCarPages)
            }

            sectionHeader("Distribuição Geográfica")
            GeographicDistributionView(breakdown: countryBreakdown, onTapMap: { showFullMap = true })

            sectionHeader("Suas Coleções Oficiais")
            if let first = sets.first {
                SetCard(brand: first.brand, info: first.info, items: first.items, totalValue: first.items.reduce(0) { $0 + $1.valorEstimadoUsd })
            }
        }
        .sheet(isPresented: $showFeedback) { FeedbackSheet() }
        .fullScreenCover(isPresented: $showFullMap) {
            NavigationStack { GeographicDistributionFullView(breakdown: countryBreakdown) }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).font(.walletHeadline)
            Spacer()
            Button {
                showFeedback = true
            } label: {
                Image(systemName: "ellipsis").foregroundStyle(.secondary)
            }
        }
    }
}

private struct BestCarPage {
    let item: WalletItem
    let badge: String
}

// MARK: - Best Cars Carousel

private struct BestCarsCarousel: View {
    let pages: [BestCarPage]
    @State private var detailItem: WalletItem?

    var body: some View {
        TabView {
            ForEach(pages, id: \.badge) { page in
                VStack(spacing: Theme.Spacing.md) {
                    Text(page.item.modelo).font(.subheadline).fontWeight(.semibold)

                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [Theme.rarityColor(page.item.raridade).opacity(0.6), Theme.rarityColor(page.item.raridade).opacity(0.15)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: 130)
                        .overlay(Image(systemName: "car.side.fill").font(.system(size: 40)).foregroundStyle(Theme.rarityColor(page.item.raridade)))

                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)

                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "laurel.leading").font(.title2).foregroundStyle(.secondary)
                        VStack(spacing: 2) {
                            Text(valueLine(for: page))
                                .font(.system(.title3, design: .rounded, weight: .heavy))
                            Text(page.badge)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "laurel.trailing").font(.title2).foregroundStyle(.secondary)
                    }

                    // Reserva espaço pra bolinha de paginação não cobrir o texto.
                    Spacer(minLength: 22)
                }
                .padding(Theme.Spacing.md)
                .glassCard()
                .contentShape(Rectangle())
                .onTapGesture { detailItem = page.item }
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 320)
        .fullScreenCover(item: $detailItem) { item in
            CarDetailPageView(item: item, canPublish: true)
        }
    }

    private func valueLine(for page: BestCarPage) -> String {
        switch page.badge {
        case "Mais Rápido":
            return page.item.aceleracao0a100.map { String(format: "%.1fs · 0-100km/h", $0) } ?? "—"
        case "Mais Raro":
            return "Raridade \(page.item.raridade)/10"
        default:
            return page.item.valorEstimadoUsd.asDollars
        }
    }
}

// MARK: - Geographic Distribution

private struct GeographicDistributionView: View {
    let breakdown: [(info: CarBrandInfo, count: Int)]
    let onTapMap: () -> Void

    private var top3: [(info: CarBrandInfo, count: Int)] { Array(breakdown.prefix(3)) }
    private var totalCount: Int { breakdown.reduce(0) { $0 + $1.count } }

    private var position: MapCameraPosition {
        guard let first = breakdown.first else {
            return .region(MKCoordinateRegion(center: .init(latitude: 20, longitude: 0), span: .init(latitudeDelta: 100, longitudeDelta: 150)))
        }
        return .region(MKCoordinateRegion(center: first.info.coordinate, span: .init(latitudeDelta: 60, longitudeDelta: 60)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("\(totalCount) carro\(totalCount == 1 ? "" : "s") distribuído\(totalCount == 1 ? "" : "s") em \(breakdown.count) país\(breakdown.count == 1 ? "" : "es")")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // Só o mapa dentro da box — países e "Ver Todos" ficam fora.
            // allowsHitTesting(false) + Color.clear por cima em vez de
            // onTapGesture direto no Map: encadear onTapGesture depois de
            // allowsHitTesting(false) é inconsistente, o toque não pegava.
            Map(initialPosition: position) {
                ForEach(breakdown, id: \.info.country) { entry in
                    Annotation(entry.info.country, coordinate: entry.info.coordinate, anchor: .bottom) {
                        MapPinAnnotation(country: entry.info.country, count: entry.count)
                    }
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .allowsHitTesting(false)
            .overlay {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { onTapMap() }
            }
            .glassCard()

            ForEach(top3, id: \.info.country) { entry in
                HStack {
                    FlagBadge(country: entry.info.country)
                    Text(entry.info.country).font(.subheadline)
                    Spacer()
                    Text("\(entry.count) carro\(entry.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Ver Todos", action: onTapMap)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .contentShape(Rectangle())
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .buttonStyle(.plain)
        }
    }
}

// MARK: - Set card (reutilizado no Summary e na aba Sets)

struct SetCard: View {
    let brand: String
    let info: CarBrandInfo
    let items: [WalletItem]
    let totalValue: Double

    private var count: Int { items.count }

    private var progress: Double {
        min(Double(count) / Double(info.knownModels), 1)
    }

    private var mostExpensive: WalletItem? {
        items.max { $0.valorEstimadoUsd < $1.valorEstimadoUsd }
    }

    var body: some View {
        NavigationLink(destination: SetDetailView(brand: brand, info: info, items: items)) {
            cardContent
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if let mostExpensive {
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [Theme.rarityColor(mostExpensive.raridade).opacity(0.6), Theme.rarityColor(mostExpensive.raridade).opacity(0.15)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: 100)
                    .overlay(Image(systemName: "car.side.fill").font(.system(size: 32)).foregroundStyle(Theme.rarityColor(mostExpensive.raridade)))
            } else {
                BrandLogoBadge(brand: brand)
                    .frame(height: 100)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(count)").font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(Color.accentColor)
                Text("/ \(info.knownModels) carros").font(.subheadline).foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(Color.accentColor)

            Text(brand).font(.walletHeadline)
            Text("Você coletou \(Int(progress * 100))% dessa marca")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(totalValue.asDollars)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

#Preview {
    ScrollView { WalletSummaryView(items: WalletItem.sample).padding() }
}
