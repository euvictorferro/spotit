import SwiftUI

struct ResultView: View {
    let carInfo: CarInfo
    let image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    }

                    if carInfo.reconhecido {
                        Text(carInfo.modelo ?? "").font(.title2).bold()
                        if let ano = carInfo.ano { Text("Ano: \(ano)") }
                        if let motor = carInfo.motor { Text("Motor: \(motor)") }
                        if let raridade = carInfo.raridade { Text("Raridade: \(raridade)/10") }
                        if let valor = carInfo.valorEstimadoUsd {
                            Text("Valor estimado: $\(valor, specifier: "%.0f")")
                        }
                        if let fato = carInfo.fatoInteressante {
                            Text(fato).font(.footnote).foregroundStyle(.secondary)
                        }

                        Button(isSaving ? "Salvando..." : "Salvar na Wallet") {
                            Task { await save() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving)
                    } else {
                        Text("Não conseguimos identificar esse carro.")
                    }

                    if let saveError {
                        Text(saveError).foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        guard let image, let data = image.jpegData(compressionQuality: 0.7) else { return }
        isSaving = true
        saveError = nil
        do {
            let url = try await SupabaseService.uploadPhoto(imageData: data)
            try await SupabaseService.saveWalletItem(car: carInfo, fotoUrl: url, lat: nil, lng: nil)
            dismiss()
        } catch {
            saveError = "Não foi possível salvar. Tenta de novo."
        }
        isSaving = false
    }
}
