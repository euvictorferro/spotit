import Foundation

struct CarEvent: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let date: String
    let attendees: Int

    static let sample: [CarEvent] = [
        CarEvent(name: "Cars & Coffee Naples", location: "Naples, FL", date: "Sáb, 30 de agosto · 8h", attendees: 214),
        CarEvent(name: "Exotic Car Meet Miami", location: "Miami, FL", date: "Dom, 31 de agosto · 17h", attendees: 892),
        CarEvent(name: "Orlando Supercar Sunday", location: "Orlando, FL", date: "Dom, 7 de setembro · 10h", attendees: 156),
    ]
}
