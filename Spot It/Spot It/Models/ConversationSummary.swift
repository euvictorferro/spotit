import Foundation

/// Uma conversa da lista do DM, já com o outro participante resolvido —
/// o backend faz esse join (ver SupabaseService.fetchConversations).
struct ConversationSummary: Decodable, Identifiable {
    let id: UUID
    let otherUserId: UUID
    let otherUsername: String
    let otherAvatarUrl: String?
    let lastMessageText: String?
    let lastMessageAt: Date
}
