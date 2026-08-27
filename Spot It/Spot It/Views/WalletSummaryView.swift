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
                SetCard(brand: first.brand, info: first.info, count: first.items.count)
            }
        }
        .sheet(isPresented: $showFeedback) { FeedbackSheet() }
        .fullScreenCover(isPresented: $showFullMap) {
            NavigationStack { GeographicDistributionFullView(breakdown: countryBreakdown) }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).font(.headline)
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

                    VStack(spacing: 2) {
                        Text(valueLine(for: page))
                            .font(.system(.title3, design: .rounded, weight: .heavy))
                        Text(page.badge)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    // Reserva espaço pra bolinha de paginação não cobrir o texto.
                    Spacer(minLength: 22)
                }
                .padding(Theme.Spacing.md)
                .card()
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 300)
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

            Map(initialPosition: position) {
                ForEach(breakdown, id: \.info.country) { entry in
                    Annotation(entry.info.country, coordinate: entry.info.coordinate) {
                        ZStack {
                            Circle().fill(.white).frame(width: 30, height: 30)
                            Circle().stroke(Color.accentColor, lineWidth: 2).frame(width: 30, height: 30)
                            Text("\(entry.count)").font(.caption).fontWeight(.bold).foregroundStyle(.black)
                        }
                    }
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .allowsHitTesting(false)
            .onTapGesture { onTapMap() }

            ForEach(top3, id: \.info.country) { entry in
                HStack {
                    FlagBadge(flag: entry.info.flag)
                    Text(entry.info.country).font(.subheadline)
                    Spacer()
                    Text("\(entry.count) carro\(entry.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if breakdown.count > 3 {
                Button("Ver Todos") { onTapMap() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
        }
        .card()
    }
}

// MARK: - Set card (reutilizado no Summary e na aba Sets)

struct SetCard: View {
    let brand: String
    let info: CarBrandInfo
    let count: Int

    private var progress: Double {
        min(Double(count) / Double(info.knownModels), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Color.accentColor.opacity(0.18))
                .frame(height: 100)
                .overlay(Image(systemName: "car.side.fill").font(.system(size: 34)).foregroundStyle(Color.accentColor))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(count)").font(.title3).fontWeight(.heavy).foregroundStyle(Color.accentColor)
                Text("/ \(info.knownModels) carros").font(.subheadline).foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(Color.accentColor)

            Text(brand).font(.headline)
            Text("Você coletou \(Int(progress * 100))% dessa marca")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.md)
        .card()
    }
}

#Preview {
    ScrollView { WalletSummaryView(items: WalletItem.sample).padding() }
}
