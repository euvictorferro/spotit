import Foundation

/// Comentário de um post do feed. Local por enquanto (não persiste) —
/// vira real quando o Feed for conectado ao backend.
struct Comment: Identifiable {
    let id = UUID()
    let username: String
    let text: String

    static func sampleFor(_ post: FeedPost) -> [Comment] {
        [
            Comment(username: post.likedByUsername, text: "que carro é esse cara, insano 🔥"),
            Comment(username: "carspotter_fl", text: "onde foi isso?"),
        ]
    }
}
