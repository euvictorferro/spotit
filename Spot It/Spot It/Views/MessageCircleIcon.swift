import SwiftUI

/// Réplica do ícone "message-circle" da Lucide (círculo + rabinho de balão) —
/// não existe equivalente exato em SF Symbols, então desenhamos o path.
struct MessageCircleIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()

        let center = CGPoint(x: rect.minX + w * 0.52, y: rect.minY + h * 0.45)
        let radius = min(w, h) * 0.42
        path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)

        path.move(to: CGPoint(x: rect.minX + w * 0.33, y: rect.minY + h * 0.79))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.17, y: rect.minY + h * 0.95))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.45, y: rect.minY + h * 0.83))

        return path
    }
}

extension MessageCircleIcon {
    /// Versão pronta pra usar como ícone de ação, no mesmo tamanho dos SF Symbols vizinhos.
    static func icon(size: CGFloat = 20) -> some View {
        MessageCircleIcon()
            .stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

#Preview {
    MessageCircleIcon.icon(size: 40)
        .padding()
}
