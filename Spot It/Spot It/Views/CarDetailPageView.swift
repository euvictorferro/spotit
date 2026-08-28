import SwiftUI

/// Página de informação de cada carro coletado — aberta ao tocar em
/// qualquer carro salvo na Wallet (Summary, All, Sets). Segue a estrutura
/// de referência: hero+valor, gauge de raridade em arco + mintage +
/// análises, feedback, série, variante mais rara, specs físicas, detalhes
/// do interior, feedback de novo + CTA de seguir o Instagram.
struct CarDetailPageView: View {
    let item: WalletItem
    @Environment(\.dismiss) private var dismiss
    @State private var valueFeedback: Bool?
    @State private var infoFeedback: Bool?

    private var brandInfo: CarBrandInfo? { CarBrandInfo.info(for: item.modelo) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    hero
                    titleAndValue

                    ArcGaugeView(raridade: item.raridade)

                    if let producao = item.producaoTotal {
                        mintageBlock(producao)
                    }

                    if let analiseRaridade = item.analiseRaridade {
                        paragraphSection(title: "Análise de Raridade", text: analiseRaridade)
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

                    if hasInteriorDetails {
                        Divider()
                        moreDetailsSection
                    }

                    Divider()
                    FeedbackPromptView(question: "Encontrou o que procurava?", answer: $infoFeedback)

                    instagramCTA
                }
                .padding(Theme.Spacing.md)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
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

    // MARK: - Mintage

    private func mintageBlock(_ producao: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: "\(producao)")
                .font(.system(.title, design: .rounded, weight: .heavy))
            Text("Unidades produzidas").font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func paragraphSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title).font(.headline)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: - Série

    private func seriesSection(_ serie: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Série").font(.headline)
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
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    // MARK: - Variante mais rara

    private func rareVariantSection(_ variante: CarInfo.VarianteCarro) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Variante Mais Rara").font(.headline)

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
        .card()
    }

    // MARK: - Physical Features

    private var hasPhysicalSpecs: Bool {
        item.potenciaCv != nil || item.aceleracao0a100 != nil || item.velocidadeMaximaKmh != nil
            || item.pesoKg != nil || item.entreEixosMm != nil || item.comprimentoMm != nil
    }

    private var physicalFeaturesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Características Físicas").font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                if let cv = item.potenciaCv { specTile(icon: "bolt.fill", label: "Potência", value: "\(cv) cv") }
                if let acc = item.aceleracao0a100 { specTile(icon: "speedometer", label: "0-100 km/h", value: String(format: "%.1fs", acc)) }
                if let vmax = item.velocidadeMaximaKmh { specTile(icon: "gauge.with.needle.fill", label: "Vel. máxima", value: "\(vmax) km/h") }
                if let peso = item.pesoKg { specTile(icon: "scalemass.fill", label: "Peso", value: "\(peso) kg") }
                if let entreEixos = item.entreEixosMm { specTile(icon: "arrow.left.and.right", label: "Entre-eixos", value: "\(entreEixos) mm") }
                if let comprimento = item.comprimentoMm { specTile(icon: "ruler.fill", label: "Comprimento", value: "\(comprimento) mm") }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if let brandInfo { detailRow("País", "\(brandInfo.flag) \(brandInfo.country)") }
                if let producao = item.producaoTotal { detailRow("Unidades produzidas", "\(producao)") }
                if let composicao = item.composicao { detailRow("Composição", composicao) }
                if let designer = item.designer { detailRow("Designer", designer) }
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }

    private func specTile(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon).foregroundStyle(Color.accentColor)
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    // MARK: - Mais detalhes (interior)

    private var hasInteriorDetails: Bool {
        item.materialBancos != nil || item.materialVolante != nil || item.interiorDestaque != nil
    }

    private var moreDetailsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Mais Detalhes").font(.headline)
            if let bancos = item.materialBancos { detailRow("Bancos", bancos) }
            if let volante = item.materialVolante { detailRow("Volante", volante) }
            if let destaque = item.interiorDestaque {
                Text(destaque).font(.footnote).foregroundStyle(.secondary)
            }
        }
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
        .card()
    }
}

#Preview {
    CarDetailPageView(item: WalletItem.sample[0])
}
