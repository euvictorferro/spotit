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
