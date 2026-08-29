import Foundation

struct DBPost: Identifiable {
    let id: UUID
    let userId: UUID
    let username: String
    let avatarUrl: String?
    let modelo: String
    let raridade: Int
    let valorEstimadoUsd: Double
    let fotoUrl: String
    let caption: String?
    let createdAt: Date
    let likeCount: Int
    let commentCount: Int
    var likedByMe: Bool
}
