import SwiftUI
import Charts

/// Página de informação de cada carro coletado — aberta em tela cheia (não
/// como sheet/popup) ao tocar em qualquer carro salvo na Wallet, Feed, mapa
/// ou notificações. Segue a estrutura de referência: hero+valor, gráfico de
/// valorização edge-to-edge, unidades vendidas, análises, specs físicas com
/// diagrama de dimensões, e design (interior/exterior).
struct CarDetailPageView: View {
    let item: WalletItem
    @Environment(\.dismiss) private var dismiss
    @State private var valueFeedback: Bool?
    @State private var infoFeedback: Bool?
    @State private var selectedPoint: (month: Int, value: Double)?

    private var brandInfo: CarBrandInfo? { CarBrandInfo.info(for: item.modelo) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    hero
                        .padding(.horizontal, Theme.Spacing.md)
                    titleAndValue
                        .padding(.horizontal, Theme.Spacing.md)

                    priceChart

                    if let producao = item.producaoTotal {
                        soldBlock(producao)
                            .padding(.horizontal, Theme.Spacing.md)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        ArcGaugeView(raridade: item.raridade)

                        if let analiseRaridade = item.analiseRaridade {
                            paragraphSection(title: "Análise", text: analiseRaridade)
                        }
                        if let analiseMercado = item.analiseMercado {
                            paragraphSection(title: "Mercado e Valorização", text: analiseMercado)
                        }

                        FeedbackPromptView(question: "Essa informação foi relevante?", answer: $valueFeedback)

                        if let serie = item.serie {
                            Divider()
                            seriesSection(serie)
                        }

                        if let variante = item.varianteMaisRara {
                            Divider()
                            rareVariantSection(variante)
                        }

                        if hasPhysicalSpecs {
                            Divider()
                            physicalFeaturesSection
                        }

                        if hasDesignDetails {
                            Divider()
                            carDesignSection
                        }

                        Divider()
                        FeedbackPromptView(question: "Encontrou o que procurava?", answer: $infoFeedback)

                        instagramCTA
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(GrainGradientBackground())
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero + título

    private var hero: some View {
        RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [Theme.rarityColor(item.raridade).opacity(0.55), Theme.rarityColor(item.raridade).opacity(0.15)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(height: 220)
            .overlay(Image(systemName: "car.side.fill").font(.system(size: 60)).foregroundStyle(Theme.rarityColor(item.raridade)))
            .rarityPhotoBorder(item.raridade)
    }

    private var titleAndValue: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.modelo).font(.title3).fontWeight(.bold)
                if let ano = item.ano {
                    Text(verbatim: "· \(ano)").font(.title3).foregroundStyle(.secondary)
                }
            }
            Text(item.valorEstimadoUsd.asDollars)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
            if let motor = item.motor {
                Text(motor).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Gráfico de valorização

    /// Histórico sintético de valorização (não temos série real ainda) —
    /// sempre termina no valor atual do carro, com uma curva plausível de
    /// alta. Determinístico por carro (seed no nome) pra não "tremer" a
    /// cada redesenho da tela.
    private var priceHistory: [(month: Int, value: Double)] {
        var rng = SeededGenerator(seed: item.modelo.hashValue)
        let points = 12
        return (0..<points).map { i in
            let progress = Double(i) / Double(points - 1)
            let noise = Double.random(in: 0.88...1.06, using: &rng)
            let value = item.valorEstimadoUsd * (0.72 + 0.28 * progress) * noise
            return (i, value)
        }
    }

    /// Data aproximada de cada ponto — só pro rótulo ao tocar no gráfico,
    /// os valores em si são sintéticos (ver priceHistory).
    private func date(forMonth month: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: -(11 - month), to: Date()) ?? Date()
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM/yy"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    /// Sai quase até a borda da tela dos dois lados — só o padding mínimo
    /// de safe area, sem o padding.horizontal padrão do resto do conteúdo.
    /// Tocar/arrastar no gráfico mostra o valor e o mês daquele ponto.
    private var priceChart: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text("Valorização").font(.walletHeadline)
                Spacer()
                if let selectedPoint {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(selectedPoint.value.asDollars)
                            .font(.subheadline).fontWeight(.bold)
                        Text(Self.monthFormatter.string(from: date(forMonth: selectedPoint.month)))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)

            Chart(priceHistory, id: \.month) { point in
                LineMark(x: .value("Mês", point.month), y: .value("Valor", point.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.rarityColor(item.raridade))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                AreaMark(x: .value("Mês", point.month), y: .value("Valor", point.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.rarityColor(item.raridade).opacity(0.35), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                if let selectedPoint {
                    RuleMark(x: .value("Mês", selectedPoint.month))
                        .foregroundStyle(.white.opacity(0.3))
                    PointMark(x: .value("Mês", selectedPoint.month), y: .value("Valor", selectedPoint.value))
                        .foregroundStyle(.white)
                        .symbolSize(80)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 160)
            .padding(.horizontal, 4)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let x = drag.location.x - geo[plotFrame].origin.x
                                    guard let month: Int = proxy.value(atX: x) else { return }
                                    selectedPoint = priceHistory.min { abs($0.month - month) < abs($1.month - month) }
                                }
                                .onEnded { _ in selectedPoint = nil }
                        )
                }
            }
        }
    }

    // MARK: - Unidades vendidas

    private func soldBlock(_ producao: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "\(producao)")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                Text("Unidades vendidas").font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func paragraphSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title).font(.walletHeadline)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: - Série

    private func seriesSection(_ serie: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Série").font(.walletHeadline)
            HStack {
                Text(item.modelo.replacingOccurrences(of: serie, with: "").trimmingCharacters(in: .whitespaces))
                    .font(.subheadline)
                Text(serie)
                    .font(.subheadline).fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.accentColor, in: Capsule())
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
    }

    // MARK: - Variante mais rara

    private func rareVariantSection(_ variante: CarInfo.VarianteCarro) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Variante Mais Rara").font(.walletHeadline)

            HStack(spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Seu Carro").font(.caption).foregroundStyle(.secondary)
                    Text(item.valorEstimadoUsd.asDollars).font(.subheadline).fontWeight(.bold)
                    Text(verbatim: "\(item.ano ?? 0)").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right").foregroundStyle(.tertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(variante.nome).font(.caption).foregroundStyle(Theme.rarityColor(10))
                    Text(variante.valorEstimadoUsd.asDollars).font(.subheadline).fontWeight(.bold)
                    Text(verbatim: "\(variante.ano)").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(variante.descricao)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.md)
        .glassCard()
    }

    // MARK: - Physical Features

    private var hasPhysicalSpecs: Bool {
        item.potenciaCv != nil || item.aceleracao0a100 != nil || item.velocidadeMaximaKmh != nil
            || item.pesoKg != nil || item.entreEixosMm != nil || item.comprimentoMm != nil
    }

    private var physicalFeaturesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Características Físicas").font(.walletHeadline)

            CarDimensionDiagram(raridade: item.raridade)
                .frame(maxWidth: .infinity)
                .frame(height: 160)

            HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                if let entreEixos = item.entreEixosMm {
                    coloredSpecLine(color: .blue, label: "Entre-eixos", value: "\(entreEixos) mm")
                }
                if let comprimento = item.comprimentoMm {
                    coloredSpecLine(color: .red, label: "Comprimento", value: "\(comprimento) mm")
                    coloredSpecLine(color: .green, label: "Altura", value: "\(estimatedWidthMm(from: comprimento)) mm")
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if let brandInfo {
                    HStack {
                        Text("País").foregroundStyle(.secondary)
                        Spacer()
                        FlagBadge(country: brandInfo.country, size: 20)
                        Text(brandInfo.country)
                    }
                    .font(.subheadline)
                }
                if let peso = item.pesoKg { detailRow("Peso", "\(peso) kg") }
                if let cv = item.potenciaCv { detailRow("Potência", "\(cv) cv") }
                if let designer = item.designer { detailRow("Designer", designer) }
            }
            .padding(.top, Theme.Spacing.xs)

            if item.potenciaCv != nil || item.aceleracao0a100 != nil || item.velocidadeMaximaKmh != nil {
                HStack(spacing: Theme.Spacing.sm) {
                    if let cv = item.potenciaCv { specTile(icon: "bolt.fill", label: "Potência", value: "\(cv) cv", compact: true) }
                    if let acc = item.aceleracao0a100 { specTile(icon: "speedometer", label: "0-100 km/h", value: String(format: "%.1fs", acc), compact: true) }
                    if let vmax = item.velocidadeMaximaKmh { specTile(icon: "gauge.with.needle.fill", label: "Vel. máxima", value: "\(vmax) km/h", compact: true) }
                }
            }
        }
    }

    private func coloredSpecLine(color: Color, label: String, value: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Rectangle().fill(color).frame(width: 3, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline).fontWeight(.semibold)
            }
        }
    }

    private func specTile(icon: String, label: String, value: String, compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon).font(compact ? .footnote : .body).foregroundStyle(Color.accentColor)
            Text(value).font(compact ? .footnote : .subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? Theme.Spacing.sm : Theme.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    // MARK: - Car Design (interior + exterior)

    private var hasDesignDetails: Bool {
        item.materialBancos != nil || item.materialVolante != nil || item.interiorDestaque != nil
            || item.composicao != nil || item.comprimentoMm != nil
    }

    private var carDesignSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Design do Carro").font(.walletHeadline)

            if item.materialBancos != nil || item.materialVolante != nil || item.interiorDestaque != nil {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Interior").font(.headline)
                    Text(interiorText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if item.composicao != nil || item.comprimentoMm != nil {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Exterior").font(.headline)
                    Text(exteriorText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// ponytail: sem coluna de altura no banco ainda — estimativa a partir
    /// do comprimento (proporção típica ~40%) até termos o dado real.
    private func estimatedWidthMm(from comprimento: Int) -> Int {
        Int(Double(comprimento) * 0.4)
    }

    /// Texto de interior gerado a partir dos specs que temos, em prosa —
    /// vira campo real (designInterior) quando o backend passar a salvar isso.
    private var interiorText: String {
        var parts: [String] = []
        if let bancos = item.materialBancos {
            parts.append("Os bancos são de \(bancos.lowercased())")
        }
        if let volante = item.materialVolante {
            parts.append(parts.isEmpty ? "O volante é de \(volante.lowercased())" : "o volante é de \(volante.lowercased())")
        }
        var text = parts.joined(separator: ", ").capitalizedFirst
        if !text.isEmpty { text += "." }
        if let destaque = item.interiorDestaque {
            text += (text.isEmpty ? "" : " ") + destaque
        }
        return text.isEmpty ? "Sem detalhes de interior disponíveis." : text
    }

    /// Texto de exterior gerado a partir dos specs que temos — vira campo
    /// real (designExterior) quando o backend passar a salvar isso.
    private var exteriorText: String {
        var parts: [String] = []
        if let comprimento = item.comprimentoMm {
            parts.append("Comprimento de \(comprimento) mm")
            parts.append("altura de \(estimatedWidthMm(from: comprimento)) mm")
        }
        if let entreEixos = item.entreEixosMm {
            parts.append("entre-eixos de \(entreEixos) mm")
        }
        if let composicao = item.composicao {
            parts.append("construção em \(composicao.lowercased())")
        }
        guard !parts.isEmpty else { return "Sem detalhes de exterior disponíveis." }
        return parts.joined(separator: ", ").capitalizedFirst + "."
    }

    // MARK: - Instagram CTA

    private var instagramCTA: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "camera.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text("Fique por dentro").font(.headline)
            Text("Siga o Spot It no Instagram pra ver os carros mais raros da comunidade.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Link(destination: URL(string: "https://instagram.com/spotit.app")!) {
                Text("Seguir")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .glassCard()
    }
}

/// Diagrama de dimensões — modelo 3D wireframe (imagem gerada, ver Assets
/// "CarDimensionDiagram") já com as setas de entre-eixos (azul), comprimento
/// (vermelho) e altura (verde) embutidas. Genérico pra todos os carros por
/// enquanto — trocar por render específico por modelo é trabalho futuro.
private struct CarDimensionDiagram: View {
    let raridade: Int

    var body: some View {
        Image("CarDimensionDiagram")
            .resizable()
            .scaledToFit()
    }
}

/// PRNG determinístico (LCG simples) — só pra desenhar o gráfico com a
/// "mesma aleatoriedade" a cada vez que a tela redesenha, sem tremer.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}

#Preview {
    CarDetailPageView(item: WalletItem.sample[0])
}
