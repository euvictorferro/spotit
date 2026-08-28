import SwiftUI

/// Sistema de design central do Spot It — cores de raridade e espaçamento,
/// pra manter as telas consistentes sem repetir valores mágicos em cada view.
enum Theme {
    /// Espaçamento em grid de 8pt.
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
    }

    static let cornerRadius: CGFloat = 12

    /// Cor da raridade (1-10) — separada do accent do app pra não confundir
    /// "ação" (vermelho) com "valor da coleção" (escala tipo loot de jogo).
    static func rarityColor(_ raridade: Int) -> Color {
        switch raridade {
        case ...3: return .gray
        case 4...6: return .blue
        case 7...8: return .purple
        default: return .yellow // 9-10, "dourado"
        }
    }

    /// Glow proporcional à raridade — sutil de propósito (feedback: "estava forte demais").
    static func rarityGlow(_ raridade: Int) -> CGFloat {
        raridade >= 9 ? 6 : (raridade >= 7 ? 4 : 0)
    }

    /// Rótulo de raridade pra headline da página de detalhe do carro.
    static func rarityLabel(_ raridade: Int) -> String {
        switch raridade {
        case ...2: return "Super Comum"
        case 3...4: return "Comum"
        case 5...6: return "Incomum"
        case 7...8: return "Raro"
        case 9: return "Muito Raro"
        default: return "Lendário"
        }
    }
}

extension Double {
    /// "$1.234.567" — sempre símbolo $ na frente + separador de milhar "."
    /// (o formatter de currency padrão do sistema vira "US$" no pt-BR).
    var asDollars: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
        return "$\(number)"
    }
}

extension Int {
    /// "1.000" — mesmo separador de milhar do asDollars, pra contadores
    /// (curtidas, comentários) ficarem consistentes com o resto do app.
    var formattedCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

/// Fundo em degradê vermelho — visual de referência (apps de
/// carteira/cripto). Usado em todas as telas principais do menu.
struct AppGradientBackground: View {
    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [Color(red: 0.55, green: 0.05, blue: 0.04), Color(red: 0.12, green: 0.01, blue: 0.01), .black],
                center: .topLeading,
                startRadius: 10,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

/// Pin de mapa em formato "balão" com haste — bandeira + contagem numa
/// pílula branca, bico apontando pro ponto exato, com uma hastezinha
/// vertical descendo até a coordenada (visual de referência).
struct MapPinAnnotation: View {
    let country: String
    let count: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                FlagBadge(country: country, size: 20)
                Text("\(count)").font(.footnote).fontWeight(.bold).foregroundStyle(.black)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white, in: Capsule())
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)

            PinTriangle()
                .fill(Color.white)
                .frame(width: 10, height: 6)

            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: 16)
        }
    }
}

private struct PinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

extension Font {
    /// Fonte "chunky" arredondada usada nos títulos de seção da Wallet
    /// (referência CoinSnap) — maior e mais pesada que um .headline normal.
    static var walletHeadline: Font {
        .system(.title2, design: .rounded, weight: .heavy)
    }
}

extension View {
    /// Card neutro (sem cor de raridade) — pra conteúdo genérico agrupado.
    func card() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(Color(.secondarySystemBackground))
            )
    }

    /// Card translúcido usado na Wallet sobre o fundo gradiente — o blur
    /// pega o que está atrás, então fica mais "quente" perto do topo da
    /// tela. Borda clara fina em volta, como na referência.
    func glassCard() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
    }

    /// Aplica borda + glow de raridade num card.
    func rarityCard(_ raridade: Int) -> some View {
        let color = Theme.rarityColor(raridade)
        return self
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(color.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.5), radius: Theme.rarityGlow(raridade))
    }

    /// Mesmo tratamento, mas pra foto full-bleed (sem padding/fundo) — feed.
    func rarityPhotoBorder(_ raridade: Int) -> some View {
        let color = Theme.rarityColor(raridade)
        return self
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(color.opacity(raridade <= 3 ? 0.5 : 0.85), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.45), radius: Theme.rarityGlow(raridade))
    }
}
