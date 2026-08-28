import CoreLocation

struct CarSpot: Identifiable {
    let id = UUID()
    let modelo: String
    let username: String
    let isMine: Bool
    let coordinate: CLLocationCoordinate2D
    let ano: Int
    let raridade: Int
    let valorEstimadoUsd: Double
    let motor: String
    let fatoInteressante: String

    /// Detalhe completo pra abrir a mesma CarDetailPageView usada no feed/wallet.
    var detail: WalletItem {
        WalletItem(modelo: modelo, ano: ano, raridade: raridade, valorEstimadoUsd: valorEstimadoUsd, motor: motor, fatoInteressante: fatoInteressante)
    }

    // Naples/Orlando/Miami, FL — região onde o Victor mora.
    static let sample: [CarSpot] = [
        CarSpot(
            modelo: "Bugatti Chiron Super Sport", username: "motor_teresa", isMine: false,
            coordinate: .init(latitude: 26.1420, longitude: -81.7948),
            ano: 2022, raridade: 10, valorEstimadoUsd: 2_700_000,
            motor: "8.0L W16 Quad-Turbo, 1.578 cv",
            fatoInteressante: "Apenas 30 unidades produzidas — um dos carros de rua mais rápidos já feitos."
        ),
        CarSpot(
            modelo: "Porsche 911 GT3 RS", username: "rk.spotter", isMine: false,
            coordinate: .init(latitude: 25.7617, longitude: -80.1918),
            ano: 2023, raridade: 8, valorEstimadoUsd: 223_000,
            motor: "4.0L Flat-6 Aspirado, 518 cv",
            fatoInteressante: "O pacote aerodinâmico gera mais downforce que um GT3 de corrida da geração anterior."
        ),
        CarSpot(
            modelo: "BMW M4 Competition", username: "jsilva_cars", isMine: false,
            coordinate: .init(latitude: 28.5383, longitude: -81.3792),
            ano: 2023, raridade: 5, valorEstimadoUsd: 78_500,
            motor: "3.0L Reto-6 Twin-Turbo, 503 cv",
            fatoInteressante: "A cor Isle of Man Green é uma homenagem ao M3 original dos anos 90."
        ),
        CarSpot(
            modelo: "Lamborghini Huracán", username: "victorferro", isMine: true,
            coordinate: .init(latitude: 26.1224, longitude: -81.7654),
            ano: 2022, raridade: 8, valorEstimadoUsd: 260_000,
            motor: "5.2L V10 Aspirado, 630 cv",
            fatoInteressante: "Um dos últimos V10 aspirados da Lamborghini antes da eletrificação da linha."
        ),
        CarSpot(
            modelo: "Ferrari 296 GTB", username: "victorferro", isMine: true,
            coordinate: .init(latitude: 26.1502, longitude: -81.8102),
            ano: 2023, raridade: 9, valorEstimadoUsd: 320_000,
            motor: "3.0L V6 Híbrido Twin-Turbo, 830 cv",
            fatoInteressante: "Primeiro V6 de rua da Ferrari — combina motor menor com um motor elétrico de 167 cv."
        ),
    ]
}
