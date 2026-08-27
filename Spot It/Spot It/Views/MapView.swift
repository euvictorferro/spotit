import SwiftUI

enum MapScope {
    /// Mostra só as fotos do próprio usuário (aberto a partir da Wallet).
    case wallet
    /// Mostra fotos do usuário + de quem ele segue (aberto a partir do Feed).
    case feed
}

struct MapView: View {
    let scope: MapScope

    var body: some View {
        EmptyStateView(
            icon: "map",
            message: scope == .wallet
                ? "Em construção — mapa com a localização das suas fotos."
                : "Em construção — mapa com as fotos suas e de quem você segue."
        )
        .navigationTitle("Mapa")
    }
}

#Preview {
    NavigationStack { MapView(scope: .feed) }
}
