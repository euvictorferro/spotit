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

    private var spots: [CarSpot] {
        scope == .wallet ? CarSpot.sample.filter(\.isMine) : CarSpot.sample
    }

    var body: some View {
        Map(position: $position) {
            ForEach(spots) { spot in
                Marker(spot.modelo, systemImage: "car.fill", coordinate: spot.coordinate)
                    .tint(spot.isMine ? Color.accentColor : .blue)
            }
        }
        .navigationTitle("Mapa")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            Text(scope == .wallet ? "Mostrando: só suas fotos" : "Mostrando: você + quem você segue")
                .font(.caption)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(.thinMaterial, in: Capsule())
                .padding(.bottom, Theme.Spacing.lg)
        }
    }
}

#Preview {
    NavigationStack { MapView(scope: .feed) }
}
