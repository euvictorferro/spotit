import SwiftUI

/// Gauge de raridade em formato de arco (semicírculo) com um ícone marcando
/// a posição — usado na página de detalhe do carro.
struct ArcGaugeView: View {
    let raridade: Int

    private var progress: Double { Double(raridade) / 10 }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(Theme.rarityLabel(raridade))
                .font(.title3).fontWeight(.bold)
                .foregroundStyle(Theme.rarityColor(raridade))

            GeometryReader { geo in
                let radius = min(geo.size.width / 2, geo.size.height)
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
                            x: center.x + radius * CGFloat(cos(markerAngle.radians)),
                            y: center.y + radius * CGFloat(sin(markerAngle.radians))
                        )
                }
            }
            .frame(height: 90)
            .padding(.horizontal, Theme.Spacing.lg)

            HStack {
                Text("Comum").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Lendário").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

/// Arco que vai de 180° (esquerda) até 180°+180°*progress — semicírculo
/// aberto pra cima, com o centro na base do frame.
private struct GaugeArc: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width / 2, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        path.addArc(
            center: center, radius: radius,
            startAngle: .degrees(180), endAngle: .degrees(180 + 180 * progress),
            clockwise: false
        )
        return path
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
