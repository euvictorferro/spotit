import Foundation

struct DBPost: Identifiable {
    let id: UUID
    let userId: UUID
    let username: String
    let avatarUrl: String?
    /// nil = post casual (câmera do feed, sem carro/IA) — modelo/raridade/
    /// valor só existem em posts publicados a partir de um item da Wallet.
    let modelo: String?
    let raridade: Int?
    let valorEstimadoUsd: Double?
    /// Foto de capa — sempre igual a `photos.first`, mantido separado pra
    /// não quebrar todo código que já espera uma foto única (share, etc).
    let fotoUrl: String
    /// Carrossel completo (1 a 10 fotos). Posts antigos sem post_photos
    /// caem no fallback de 1 item (fotoUrl) — ver resolvePosts().
    let photos: [String]
    let location: String?
    let caption: String?
    let createdAt: Date
    let likeCount: Int
    let commentCount: Int
    var likedByMe: Bool

    var isCarPost: Bool { modelo != nil }
}
