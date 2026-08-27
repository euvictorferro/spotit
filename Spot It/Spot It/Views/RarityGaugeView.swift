import SwiftUI

/// Gauge de raridade (rótulo + barra Comum→Lendário) — usado na tela de
/// Resultado da captura e na tela de detalhe de um carro já salvo.
struct RarityGaugeView: View {
    let raridade: Int

    private var label: String {
        switch raridade {
        case ...3: return "Comum"
        case 4...6: return "Incomum"
        case 7...8: return "Raro"
        default: return "Lendário"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(label)
                .font(.headline)
                .foregroundStyle(Theme.rarityColor(raridade))

            GeometryReader { geo in
                let progress = CGFloat(raridade) / 10
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill)).frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(colors: [.gray, .blue, .purple, .yellow], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress, height: 6)
                    Circle()
                        .fill(Theme.rarityColor(raridade))
                        .frame(width: 14, height: 14)
                        .offset(x: geo.size.width * progress - 7)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 14)

            HStack {
                Text("Comum").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Lendário").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    RarityGaugeView(raridade: 8).padding()
}
