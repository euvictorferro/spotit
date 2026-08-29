import Foundation
import SwiftUI

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
    var attendeeCount: Int
    var isGoing: Bool
}

extension DBEvent {
    /// Gradiente derivado do id do evento — usado tanto no card da lista
    /// (EventsView) quanto no cabeçalho do detalhe (EventDetailView), pra
    /// sempre baterem pro mesmo evento.
    var coverGradient: [Color] {
        let palette: [[Color]] = [
            [.red, .orange], [.purple, .indigo], [.blue, .cyan],
            [.pink, .purple], [.green, .mint], [.teal, .blue],
        ]
        let index = Int(id.uuidString.hashValue.magnitude % UInt(palette.count))
        return palette[index]
    }
}
