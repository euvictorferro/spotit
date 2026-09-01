import CoreLocation

/// Localização one-shot pro momento de salvar um carro na wallet — sem isso
/// lat/lng iam sempre nil e nenhum pin aparecia nos mapas de spots.
/// Pede permissão na hora (se ainda não foi decidida) e devolve nil se
/// negada/indisponível, sem travar o save por causa disso.
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    private override init() {
        super.init()
        manager.delegate = self
    }

    func currentLocation() async -> CLLocationCoordinate2D? {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            return nil
        case .notDetermined:
            // ponytail: primeiro save depois de instalar o app fica sem
            // localização (o usuário ainda não respondeu ao alerta) — os
            // próximos já funcionam normal, sem precisar de um segundo
            // fluxo de "espera a permissão e tenta de novo".
            manager.requestWhenInUseAuthorization()
            return nil
        default:
            break
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.last?.coordinate)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }
}
