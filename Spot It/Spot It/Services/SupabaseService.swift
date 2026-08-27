import Foundation
import Supabase

struct WalletItem: Codable, Identifiable {
    let id: UUID
    let modelo: String
    let ano: Int?
    let raridade: Int
    let valorEstimadoUsd: Double
    let fotoUrl: String
    let createdAt: Date
    /// Ainda não persiste no Supabase (coluna não existe na tabela) — só
    /// vem preenchido nos dados de exemplo. Usado pra ordenar "Mais Rápido"
    /// no carrossel da Wallet.
    let aceleracao0a100: Double?
    /// Edição especial de preparador (Mansory, Brabus, etc) — nil na maioria
    /// dos carros. Também não persiste no Supabase ainda.
    let edicaoEspecial: String?

    enum CodingKeys: String, CodingKey {
        case id, modelo, ano, raridade
        case valorEstimadoUsd = "valor_estimado_usd"
        case fotoUrl = "foto_url"
        case edicaoEspecial = "edicao_especial"
        case createdAt = "created_at"
        case aceleracao0a100 = "aceleracao_0_100"
    }
}

struct SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://mevdvmjtkkcerkakzkch.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldmR2bWp0a2tjZXJrYWt6a2NoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4NDMwOTMsImV4cCI6MjEwMzQxOTA5M30.Cm36acvnAKTfjYjFMXX8ifyY849-goGnYrO9vQyEZP0"
    )

    /// Garante que existe um usuário logado (anônimo) antes de ler/escrever na wallet.
    /// A tabela wallet_items exige user_id + RLS; sem isso, insert/select falham.
    static func ensureSignedIn() async throws {
        if client.auth.currentSession == nil {
            try await client.auth.signInAnonymously()
        }
    }

    static func uploadPhoto(imageData: Data) async throws -> String {
        try await ensureSignedIn()
        let fileName = "\(UUID().uuidString).jpg"
        try await client.storage.from("car-photos").upload(fileName, data: imageData)
        return try client.storage.from("car-photos").getPublicURL(path: fileName).absoluteString
    }

    static func saveWalletItem(car: CarInfo, fotoUrl: String, lat: Double?, lng: Double?) async throws {
        try await ensureSignedIn()
        struct NewItem: Encodable {
            let modelo: String
            let ano: Int?
            let motor: String?
            let raridade: Int
            let valor_estimado_usd: Double
            let fato_interessante: String?
            let foto_url: String
            let lat: Double?
            let lng: Double?
        }

        let item = NewItem(
            modelo: car.modelo ?? "Desconhecido",
            ano: car.ano,
            motor: car.motor,
            raridade: car.raridade ?? 1,
            valor_estimado_usd: car.valorEstimadoUsd ?? 0,
            fato_interessante: car.fatoInteressante,
            foto_url: fotoUrl,
            lat: lat,
            lng: lng
        )

        try await client.from("wallet_items").insert(item).execute()
    }

    static func fetchWalletItems() async throws -> [WalletItem] {
        try await ensureSignedIn()
        return try await client.from("wallet_items")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
