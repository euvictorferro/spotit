import Foundation

struct Profile: Decodable, Identifiable, Equatable {
    let id: UUID
    let username: String
    let displayName: String?
    let bio: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}
