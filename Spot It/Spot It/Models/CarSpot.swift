import CoreLocation

struct CarSpot: Identifiable {
    let id = UUID()
    let modelo: String
    let username: String
    let isMine: Bool
    let coordinate: CLLocationCoordinate2D

    // Naples/Orlando/Miami, FL — região onde o Victor mora.
    static let sample: [CarSpot] = [
        CarSpot(modelo: "Bugatti Chiron Super Sport", username: "motor_teresa", isMine: false, coordinate: .init(latitude: 26.1420, longitude: -81.7948)),
        CarSpot(modelo: "Porsche 911 GT3 RS", username: "rk.spotter", isMine: false, coordinate: .init(latitude: 25.7617, longitude: -80.1918)),
        CarSpot(modelo: "BMW M4 Competition", username: "jsilva_cars", isMine: false, coordinate: .init(latitude: 28.5383, longitude: -81.3792)),
        CarSpot(modelo: "Lamborghini Huracán", username: "victorferro", isMine: true, coordinate: .init(latitude: 26.1224, longitude: -81.7654)),
        CarSpot(modelo: "Ferrari 296 GTB", username: "victorferro", isMine: true, coordinate: .init(latitude: 26.1502, longitude: -81.8102)),
    ]
}
