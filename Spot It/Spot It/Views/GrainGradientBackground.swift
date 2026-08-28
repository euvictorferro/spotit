import SwiftUI

/// Fundo "grain gradient" — blobs suaves e grandes nos cantos, em tons de
/// vermelho da marca, com uma leve deriva animada. Equivalente nativo do
/// efeito @paper-design/shaders-react GrainGradient (que é uma lib React,
/// não dá pra usar num app SwiftUI) — mesma sensação visual, sem dependência
/// externa. Usado só na página de detalhe do carro por enquanto.
struct GrainGradientBackground: View {
    private let colors: [Color] = [
        Color(hue: 0.02, saturation: 0.85, brightness: 0.95),   // vermelho-laranja vivo
        Color(hue: 0.97, saturation: 0.75, brightness: 0.55),   // magenta-vermelho profundo
        Color(hue: 0.0, saturation: 0.9, brightness: 0.45),     // vermelho escuro
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Color.black
                blob(color: colors[0], corner: .topLeading, t: t, speed: 0.15)
                blob(color: colors[1], corner: .topTrailing, t: t, speed: -0.11)
                blob(color: colors[2], corner: .bottomTrailing, t: t, speed: 0.13)
            }
        }
        .ignoresSafeArea()
    }

    private func blob(color: Color, corner: UnitPoint, t: TimeInterval, speed: Double) -> some View {
        GeometryReader { geo in
            let wobbleX = sin(t * speed) * 30
            let wobbleY = cos(t * speed * 0.8) * 30
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.9), color.opacity(0)],
                        center: .center, startRadius: 0, endRadius: geo.size.width * 0.55
                    )
                )
                .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                .position(x: geo.size.width * corner.x + wobbleX, y: geo.size.height * corner.y + wobbleY)
                .blur(radius: 60)
        }
    }
}

#Preview {
    GrainGradientBackground()
}
