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
            // Sem isso, sinal de GPS fraco (dentro de casa, prédio) travava
            // o save inteiro pra sempre — requestLocation não tem timeout
            // próprio, e o "Fechar" fica desabilitado enquanto isSaving.
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                self.resumeIfNeeded(with: nil)
            }
        }
    }

    /// Garante que a continuation só é resolvida uma vez — location de
    /// verdade e o timeout podem chegar em qualquer ordem, o primeiro ganha.
    private func resumeIfNeeded(with coordinate: CLLocationCoordinate2D?) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        resumeIfNeeded(with: locations.last?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resumeIfNeeded(with: nil)
    }
}
