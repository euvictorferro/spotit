import SwiftUI

/// Comentário de um post do feed. Local por enquanto (não persiste) —
/// vira real quando o Feed for conectado ao backend.
struct Comment: Identifiable {
    let id = UUID()
    let username: String
    let text: String
    let timeAgo: String
    let avatarColors: [Color]
    var likeCount: Int = Int.random(in: 0...120)
    var isLiked: Bool = false

    var avatarInitials: String {
        String(username.prefix(2)).uppercased()
    }

    static func sampleFor(_ post: FeedPost) -> [Comment] {
        [
            Comment(username: post.likedByUsername, text: "que carro é esse cara, insano 🔥", timeAgo: "7m", avatarColors: [.orange, .red]),
            Comment(username: "carspotter_fl", text: "onde foi isso?", timeAgo: "5m", avatarColors: [.blue, .indigo]),
        ]
    }
}
