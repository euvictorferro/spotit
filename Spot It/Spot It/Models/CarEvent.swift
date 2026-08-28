import SwiftUI
import CoreLocation

struct CarEvent: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let coordinate: CLLocationCoordinate2D
    /// Data/hora já formatada pra exibição — quando plugarmos uma fonte real
    /// (Eventbrite ou similar), isso vira um `Date` de verdade + formatter.
    let dateLabel: String
    let startDate: Date
    let endDate: Date
    let attendees: Int
    let organizer: String
    let description: String
    let coverGradient: [Color]

    // ponytail: sem API de eventos automotivos pública/gratuita conectada ainda —
    // mock até decidirmos a fonte (Eventbrite genérica ou scraping dedicado).
    static let sample: [CarEvent] = [
        CarEvent(
            name: "Cars & Coffee Naples", location: "Naples, FL",
            coordinate: .init(latitude: 26.1420, longitude: -81.7948),
            dateLabel: "Sáb, 30 de agosto · 8h", startDate: Date(), endDate: Date().addingTimeInterval(3 * 3600),
            attendees: 214, organizer: "Naples Car Club",
            description: "Encontro mensal de carros esportivos e clássicos no estacionamento do Waterside Shops. Café e donuts por conta da casa nas primeiras 100 pessoas.",
            coverGradient: [Color(red: 0.05, green: 0.12, blue: 0.2), Color(red: 0.02, green: 0.04, blue: 0.07)]
        ),
        CarEvent(
            name: "Exotic Car Meet Miami", location: "Miami, FL",
            coordinate: .init(latitude: 25.7617, longitude: -80.1918),
            dateLabel: "Dom, 31 de agosto · 17h", startDate: Date().addingTimeInterval(86400), endDate: Date().addingTimeInterval(86400 + 4 * 3600),
            attendees: 892, organizer: "305 Exotics",
            description: "O maior encontro de supercarros do sul da Flórida. Espere fileiras de Lamborghini, Ferrari e McLaren em South Beach — chegue cedo, o estacionamento lota rápido.",
            coverGradient: [Color(red: 0.14, green: 0.06, blue: 0.19), Color(red: 0.04, green: 0.03, blue: 0.06)]
        ),
        CarEvent(
            name: "Orlando Supercar Sunday", location: "Orlando, FL",
            coordinate: .init(latitude: 28.5383, longitude: -81.3792),
            dateLabel: "Dom, 7 de setembro · 10h", startDate: Date().addingTimeInterval(7 * 86400), endDate: Date().addingTimeInterval(7 * 86400 + 3 * 3600),
            attendees: 156, organizer: "Orlando Motorsports Group",
            description: "Encontro dominical descontraído no estacionamento do Mall at Millenia. Aberto a qualquer carro modificado ou de performance, não só supercarros.",
            coverGradient: [Color(red: 0.23, green: 0.16, blue: 0.02), Color(red: 0.06, green: 0.04, blue: 0.01)]
        ),
    ]
}
