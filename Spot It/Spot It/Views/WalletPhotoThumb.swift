import SwiftUI

/// Foto real do carro (AsyncImage) com o mesmo placeholder de gradiente +
/// ícone de antes enquanto carrega ou se a URL falhar — usado onde a Wallet
/// mostrava só o placeholder e nunca a foto de verdade.
struct WalletPhotoThumb: View {
    let fotoUrl: String
    let raridade: Int

    var body: some View {
        AsyncImage(url: URL(string: fotoUrl)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                placeholder
            }
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [Theme.rarityColor(raridade).opacity(0.6), Theme.rarityColor(raridade).opacity(0.15)],
            startPoint: .top, endPoint: .bottom
        )
        .overlay(Image(systemName: "car.side.fill").foregroundStyle(Theme.rarityColor(raridade)))
    }
}
