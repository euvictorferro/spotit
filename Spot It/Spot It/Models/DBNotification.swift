import Foundation

struct DBNotification: Identifiable {
    let id: UUID
    let actorId: UUID
    let actorUsername: String
    let actorAvatarUrl: String?
    let kind: NotificationKind
    let postId: UUID?
    var isRead: Bool
    let createdAt: Date
}
