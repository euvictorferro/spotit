import SwiftUI

/// Aberta ao tocar em qualquer carro já salvo na wallet (Summary, All, Sets).
/// Reaproveita o mesmo visual da tela que aparece logo após tirar a foto,
/// só que a partir de um WalletItem em vez de um CarInfo recém-capturado —
/// por isso não tem foto real nem os campos que só a IA devolve na hora
/// (specs físicas, design, variante) — só o que fica salvo no banco.
struct CarDetailPageView: View {
    let item: WalletItem
    @Environment(\.dismiss) private var dismiss

    private var brandInfo: CarBrandInfo? { CarBrandInfo.info(for: item.modelo) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
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

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.modelo).font(.title3).fontWeight(.bold)
                            if let ano = item.ano {
                                Text(verbatim: "· \(ano)").font(.title3).foregroundStyle(.secondary)
                            }
                        }
                        Text(item.valorEstimadoUsd.asDollars)
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                    }

                    RarityGaugeView(raridade: item.raridade)

                    Divider()

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Detalhes").font(.headline)
                        if let brandInfo {
                            detailRow("País de origem", "\(brandInfo.flag) \(brandInfo.country)")
                        }
                        if let edicao = item.edicaoEspecial {
                            detailRow("Edição especial", edicao)
                        }
                        if let aceleracao = item.aceleracao0a100 {
                            detailRow("0-100 km/h", String(format: "%.1fs", aceleracao))
                        }
                        detailRow("Adicionado em", item.createdAt.formatted(date: .abbreviated, time: .omitted))
                    }
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

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

#Preview {
    CarDetailPageView(item: WalletItem.sample[0])
}
