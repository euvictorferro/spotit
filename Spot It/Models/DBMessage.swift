import Foundation

struct DBMessage: Decodable, Identifiable, Equatable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let text: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, text
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case createdAt = "created_at"
    }
}
