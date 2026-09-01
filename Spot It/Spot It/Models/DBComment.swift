import Foundation

struct DBComment: Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let username: String
    let avatarUrl: String?
    let text: String
    let createdAt: Date
}
