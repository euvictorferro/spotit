import CoreLocation
import SwiftUI
import UIKit

struct ResultView: View {
    let image: UIImage?
    /// Fotos já comprimidas usadas no scan — reaproveitadas pra pedir o
    /// perfil completo em background, sem precisar recomprimir nem pedir a
    /// câmera de novo.
    let imagesDataForEnrich: [Data]
    /// Fecha o fluxo de captura inteiro (não só esse sheet) — usado no
    /// "Fechar" e depois de salvar; o retake (ícone de câmera) usa o
    /// dismiss() normal, que só fecha esse resultado e volta pra câmera.
    var onFinish: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    // @State em vez de let: começa só com os 7 campos essenciais (resposta
    // rápida) e é substituído pelo perfil completo assim que a chamada de
    // enrichment em background termina.
    @State var carInfo: CarInfo
    @State private var isEnriching = true
    @State private var enrichTask: Task<Void, Never>?
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var valueFeedback: Bool?
    @State private var infoFeedback: Bool?

    init(carInfo: CarInfo, image: UIImage?, imagesDataForEnrich: [Data], onFinish: @escaping () -> Void = {}) {
        self._carInfo = State(initialValue: carInfo)
        self.image = image
        self.imagesDataForEnrich = imagesDataForEnrich
        self.onFinish = onFinish
    }

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

                            if isEnriching {
                                HStack(spacing: Theme.Spacing.xs) {
                                    ProgressView().controlSize(.small)
                                    Text("Carregando mais detalhes...")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }

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
                    // Sem o disabled aqui, fechar no meio do save matava a
                    // view antes do Task terminar — se desse erro, ninguém
                    // mais estava escutando pra mostrar o saveError.
                    Button("Fechar") { onFinish() }
                        .disabled(isSaving)
                }
            }
            .onAppear {
                // Task guardada (não .task{}) de propósito — save() precisa
                // conseguir esperar essa mesma chamada terminar antes de
                // gravar, senão salvava só os 7 campos rápidos pra sempre
                // se o usuário tocasse "Salvar" antes do enrichment chegar.
                if enrichTask == nil {
                    enrichTask = Task { await enrich() }
                }
            }
        }
    }

    /// 2ª chamada em background pedindo o perfil completo (raridade, mercado,
    /// design, variantes etc) — a 1ª (quick) já mostrou o resultado rápido.
    private func enrich() async {
        guard carInfo.reconhecido, !imagesDataForEnrich.isEmpty else {
            isEnriching = false
            return
        }
        if let full = try? await RecognizeService.recognize(imagesData: imagesDataForEnrich, quick: false), full.reconhecido {
            carInfo = full
        }
        isEnriching = false
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

    private func paragraphSection(title: LocalizedStringKey, text: String) -> some View {
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
        VStack(spacing: Theme.Spacing.sm) {
            if isLocationDenied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "location.slash")
                        Text("Localização desativada — esse carro não vai aparecer no mapa. Toque pra ativar em Ajustes.")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

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
        }
        .padding(Theme.Spacing.md)
        .background(.bar)
    }

    private var isLocationDenied: Bool {
        let status = LocationService.shared.authorizationStatus
        return status == .denied || status == .restricted
    }

    private var shareText: String {
        "Achei um \(carInfo.modelo ?? "carro raro") no Spot It! 🏎️"
    }

    private func save() async {
        guard let image else { return }
        isSaving = true
        saveError = nil

        // Mesma compressão do scan (resizedForUpload + cap) — a imagem
        // original em resolução total (12MP+) deixava o upload lento e mais
        // propenso a falhar em rede ruim.
        guard let data = image.resizedForUpload(maxDimension: 1600).jpegDataCapped(maxBytes: 900_000) else {
            isSaving = false
            return
        }
        let coordinate = await LocationService.shared.currentLocation()
        do {
            let url = try await SupabaseService.uploadPhoto(imageData: data)
            // Salva já com o que tiver pronto (rápido — não espera o
            // enrichment) e sai da tela na hora. Se o perfil completo ainda
            // não chegou, uma Task solta completa o item assim que chegar,
            // mesmo depois da tela ter fechado — sem travar o usuário aqui.
            let itemId = try await SupabaseService.saveWalletItem(car: carInfo, fotoUrl: url, lat: coordinate?.latitude, lng: coordinate?.longitude)
            onFinish()
            if isEnriching, let enrichTask {
                Task {
                    await enrichTask.value
                    try? await SupabaseService.updateWalletItemDetails(id: itemId, car: carInfo)
                }
            }
        } catch {
            saveError = "Erro ao salvar: \(error.localizedDescription)"
        }
        isSaving = false
    }
}
