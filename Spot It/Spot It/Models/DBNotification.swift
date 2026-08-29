import Foundation

enum NotificationKind: String {
    case like, comment, follow
}

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
