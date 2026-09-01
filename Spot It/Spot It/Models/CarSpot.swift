import CoreLocation

/// Um item da Wallet com localização, pra pin no mapa — envolve o
/// WalletItem real (não mais dados de exemplo), buscado por
/// SupabaseService.fetchMapSpots.
struct CarSpot: Identifiable {
    let item: WalletItem
    let username: String
    let isMine: Bool

    var id: UUID { item.id }
    var modelo: String { item.modelo }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: item.lat ?? 0, longitude: item.lng ?? 0)
    }

    /// Abre a mesma CarDetailPageView usada no feed/wallet.
    var detail: WalletItem { item }
}
