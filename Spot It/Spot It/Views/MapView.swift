import SwiftUI
import MapKit

enum MapScope {
    /// Mostra só as fotos do próprio usuário (aberto a partir da Wallet).
    case wallet
    /// Mostra fotos do usuário + de quem ele segue (aberto a partir do Feed).
    case feed
}

struct MapView: View {
    let scope: MapScope
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(center: .init(latitude: 26.14, longitude: -81.79), span: .init(latitudeDelta: 0.6, longitudeDelta: 0.6))
    )
    @State private var detailItem: WalletItem?

    // Sem localização real salva por carro ainda (a Wallet não coleta
    // lat/lng no momento da captura) — mapa vazio até isso existir.
    private var spots: [CarSpot] { [] }

    var body: some View {
        Map(position: $position) {
            ForEach(spots) { spot in
                Annotation(spot.modelo, coordinate: spot.coordinate) {
                    Button {
                        detailItem = spot.detail
                    } label: {
                        Image(systemName: "car.fill")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(spot.isMine ? Color.accentColor : .blue, in: Circle())
                    }
                }
            }
        }
        .navigationTitle("Mapa")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if spots.isEmpty {
                EmptyStateView(icon: "mappin.slash", message: "Nenhum local registrado ainda.")
            }
        }
        .overlay(alignment: .bottom) {
            if !spots.isEmpty {
                Text(scope == .wallet ? "Mostrando: só suas fotos" : "Mostrando: você + quem você segue")
                    .font(.caption)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, Theme.Spacing.lg)
            }
        }
        .fullScreenCover(item: $detailItem) { item in
            CarDetailPageView(item: item)
        }
    }
}

#Preview {
    NavigationStack { MapView(scope: .feed) }
}
