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
        VStack {
            Text("Em construção — mapa com a localização das fotos.")
                .foregroundStyle(.secondary)
                .padding()
            Text(scope == .wallet ? "Mostrando: só suas fotos" : "Mostrando: você + quem você segue")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .navigationTitle("Mapa")
    }
}

#Preview {
    NavigationStack { MapView(scope: .feed) }
}
