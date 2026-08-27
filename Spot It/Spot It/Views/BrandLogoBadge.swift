import SwiftUI

/// Fica no lugar da foto nos cards de Set — como não temos os logos reais
/// das montadoras (direitos de imagem, sem assets), usamos um monograma
/// estilizado com a inicial da marca.
struct BrandLogoBadge: View {
    let brand: String

    private var initial: String {
        String(brand.first ?? "?")
    }

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .fill(Color.accentColor.opacity(0.18))
            .overlay(
                Text(initial)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            )
    }
}

#Preview {
    BrandLogoBadge(brand: "Ferrari").frame(width: 120, height: 100).padding()
}
