import SwiftUI

/// Gauge de raridade em formato de arco (semicírculo) com um ícone marcando
/// a posição — usado na página de detalhe do carro. Arco elíptico (raio
/// horizontal maior que o vertical) pra ficar largo e baixo, ocupando
/// quase a largura toda da tela.
struct ArcGaugeView: View {
    let raridade: Int

    private var progress: Double { Double(raridade) / 10 }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(Theme.rarityLabel(raridade))
                .font(.title3).fontWeight(.bold)
                .foregroundStyle(Theme.rarityColor(raridade))

            GeometryReader { geo in
                let rx = geo.size.width / 2
                let ry = geo.size.height
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)
                let markerAngle = Angle.degrees(180 + 180 * progress)

                ZStack {
                    GaugeArc(progress: 1)
                        .stroke(Color(.tertiarySystemFill), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                    GaugeArc(progress: progress)
                        .stroke(
                            AngularGradient(colors: [.gray, .blue, .purple, .yellow], center: .center, startAngle: .degrees(180), endAngle: .degrees(360)),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )

                    Image(systemName: "car.side.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Theme.rarityColor(raridade), in: Circle())
                        .position(
                            x: center.x + rx * CGFloat(cos(markerAngle.radians)),
                            y: center.y + ry * CGFloat(sin(markerAngle.radians))
                        )
                }
            }
            .frame(height: 46)
            .padding(.horizontal, Theme.Spacing.xs)

            HStack {
                Text("Comum").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Lendário").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.sm)
        }
    }
}

/// Arco elíptico que vai de 180° (esquerda) até 180°+180°*progress —
/// semicírculo aberto pra cima, com o centro na base do frame. Raio
/// horizontal (rx) e vertical (ry) independentes pra caber num frame
/// bem mais largo que alto.
private struct GaugeArc: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let rx = rect.width / 2
        let ry = rect.height
        let center = CGPoint(x: rect.midX, y: rect.maxY)

        var unitPath = Path()
        unitPath.addArc(center: .zero, radius: 1, startAngle: .degrees(180), endAngle: .degrees(180 + 180 * progress), clockwise: false)

        let transform = CGAffineTransform(translationX: center.x, y: center.y).scaledBy(x: rx, y: ry)
        return unitPath.applying(transform)
    }
}

#Preview {
    VStack(spacing: 30) {
        ArcGaugeView(raridade: 2)
        ArcGaugeView(raridade: 6)
        ArcGaugeView(raridade: 10)
    }
    .padding()
}
