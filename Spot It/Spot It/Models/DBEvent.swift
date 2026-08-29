import Foundation

struct DBEvent: Identifiable {
    let id: UUID
    let organizerId: UUID
    let organizerUsername: String
    let name: String
    let location: String
    let lat: Double?
    let lng: Double?
    let eventDate: Date
    let description: String?
    let attendeeCount: Int
    var isGoing: Bool
}
