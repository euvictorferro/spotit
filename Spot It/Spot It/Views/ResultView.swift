import SwiftUI

struct ResultView: View {
    let carInfo: CarInfo
    let image: UIImage?
    /// Fecha o fluxo de captura inteiro (não só esse sheet) — usado no
    /// "Fechar" e depois de salvar; o retake (ícone de câmera) usa o
    /// dismiss() normal, que só fecha esse resultado e volta pra câmera.
    var onFinish: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var valueFeedback: Bool?
    @State private var infoFeedback: Bool?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        if let image {
                            heroPhoto(image)
                        }

                        if carInfo.reconhecido {
                            titleAndValue
                            RarityGaugeView(raridade: carInfo.raridade ?? 1)
                            if let analiseRaridade = carInfo.analiseRaridade {
                                paragraphSection(title: "Análise de Raridade", text: analiseRaridade)
                            }
                            if let analiseMercado = carInfo.analiseMercado {
                                paragraphSection(title: "Mercado e Valorização", text: analiseMercado)
                            }
                            FeedbackPromptView(question: "Esse valor te parece razoável?", answer: $valueFeedback)

                            Divider()
                            detailsSection

                            if let variante = carInfo.varianteEspecial {
                                Divider()
                                varianteSection(variante)
                            }

                            if hasPhysicalSpecs {
                                Divider()
                                physicalSpecsSection
                            }

                            if carInfo.designExterior != nil || carInfo.designInterior != nil {
                                Divider()
                                designSection
                            }

                            Divider()
                            FeedbackPromptView(question: "Encontrou o que procurava?", answer: $infoFeedback)

                            if let saveError {
                                Text(saveError).font(.footnote).foregroundStyle(.red)
                            }
                        } else {
                            Text("Não conseguimos identificar esse carro.")
                                .padding(.top, Theme.Spacing.lg)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .padding(.bottom, 90) // espaço pra barra fixa não cobrir o conteúdo
                }

                if carInfo.reconhecido {
                    bottomBar
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { onFinish() }
                }
            }
        }
    }

    // MARK: - Hero

    private func heroPhoto(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(alignment: .topLeading) {
                Text("Sua foto")
                    .font(.caption).fontWeight(.semibold)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.5), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(Theme.Spacing.sm)
            }
            .rarityPhotoBorder(carInfo.raridade ?? 1)
    }

    // MARK: - Title + value

    private var titleAndValue: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(carInfo.modelo ?? "Carro não identificado")
                    .font(.title3).fontWeight(.bold)
                if let ano = carInfo.ano {
                    Text(verbatim: "· \(ano)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            if let valor = carInfo.valorEstimadoUsd {
                Text(valor.asDollars)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
            }

            if let motor = carInfo.motor {
                Text(motor).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Paragraph sections

    private func paragraphSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title).font(.headline)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
    }


    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Detalhes").font(.headline)
            if let motor = carInfo.motor { detailRow("Motor", motor) }
            if let pais = carInfo.paisOrigem { detailRow("País de origem", pais) }
            if let producao = carInfo.producaoTotal {
                detailRow("Produção total", "\(producao) unidades")
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    // MARK: - Variante especial

    private func varianteSection(_ variante: CarInfo.VarianteCarro) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Variante Especial").font(.headline)
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(variante.nome).fontWeight(.semibold)
                        Text(verbatim: "\(variante.ano)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(variante.valorEstimadoUsd.asDollars)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
                Text(variante.descricao)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .card()
        }
    }

    // MARK: - Physical specs

    private var hasPhysicalSpecs: Bool {
        carInfo.potenciaCv != nil || carInfo.aceleracao0a100 != nil
            || carInfo.velocidadeMaximaKmh != nil || carInfo.pesoKg != nil
    }

    private var physicalSpecsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Características Físicas").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                if let cv = carInfo.potenciaCv {
                    specTile(icon: "bolt.fill", label: "Potência", value: "\(cv) cv")
                }
                if let acc = carInfo.aceleracao0a100 {
                    specTile(icon: "speedometer", label: "0-100 km/h", value: String(format: "%.1fs", acc))
                }
                if let vmax = carInfo.velocidadeMaximaKmh {
                    specTile(icon: "gauge.with.needle.fill", label: "Vel. máxima", value: "\(vmax) km/h")
                }
                if let peso = carInfo.pesoKg {
                    specTile(icon: "scalemass.fill", label: "Peso", value: "\(peso) kg")
                }
            }
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

    // MARK: - Design

    private var designSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Design").font(.headline)
            if let exterior = carInfo.designExterior {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Exterior").font(.subheadline).fontWeight(.semibold)
                    Text(exterior).font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let interior = carInfo.designInterior {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Interior").font(.subheadline).fontWeight(.semibold)
                    Text(interior).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "camera")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)

            Button {
                Task { await save() }
            } label: {
                Text(isSaving ? "Salvando..." : "Salvar na Wallet")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
        }
        .padding(Theme.Spacing.md)
        .background(.bar)
    }

    private var shareText: String {
        "Achei um \(carInfo.modelo ?? "carro raro") no Spot It! 🏎️"
    }

    private func save() async {
        guard let image, let data = image.jpegData(compressionQuality: 0.7) else { return }
        isSaving = true
        saveError = nil
        do {
            let url = try await SupabaseService.uploadPhoto(imageData: data)
            try await SupabaseService.saveWalletItem(car: carInfo, fotoUrl: url, lat: nil, lng: nil)
            onFinish()
        } catch {
            saveError = "Não foi possível salvar. Tenta de novo."
        }
        isSaving = false
    }
}
