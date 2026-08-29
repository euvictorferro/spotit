import Foundation
import Supabase

enum SupabaseError: LocalizedError {
    case notSignedIn
    case cannotMessageSelf

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Não autenticado — tenta de novo em alguns segundos."
        case .cannotMessageSelf:
            return "Não é possível iniciar uma conversa consigo mesmo."
        }
    }
}

struct WalletItem: Decodable, Identifiable {
    let id: UUID
    let modelo: String
    let ano: Int?
    let raridade: Int
    let valorEstimadoUsd: Double
    let fotoUrl: String
    let createdAt: Date

    let motor: String?
    let potenciaCv: Int?
    let aceleracao0a100: Double?
    let velocidadeMaximaKmh: Int?
    let pesoKg: Int?
    let producaoTotal: Int?

    let analiseRaridade: String?
    let analiseMercado: String?

    let serie: String?
    let edicaoEspecial: String?

    let varianteMaisRara: CarInfo.VarianteCarro?

    let entreEixosMm: Int?
    let comprimentoMm: Int?
    let composicao: String?
    let designer: String?

    let materialBancos: String?
    let materialVolante: String?
    let interiorDestaque: String?

    enum CodingKeys: String, CodingKey {
        case id, modelo, ano, raridade
        case valorEstimadoUsd = "valor_estimado_usd"
        case fotoUrl = "foto_url"
        case createdAt = "created_at"
        case motor
        case potenciaCv = "potencia_cv"
        case aceleracao0a100 = "aceleracao_0_100"
        case velocidadeMaximaKmh = "velocidade_maxima_kmh"
        case pesoKg = "peso_kg"
        case producaoTotal = "producao_total"
        case analiseRaridade = "analise_raridade"
        case analiseMercado = "analise_mercado"
        case serie
        case edicaoEspecial = "edicao_especial"
        case varianteMaisRaraNome = "variante_mais_rara_nome"
        case varianteMaisRaraAno = "variante_mais_rara_ano"
        case varianteMaisRaraValorUsd = "variante_mais_rara_valor_usd"
        case varianteMaisRaraDescricao = "variante_mais_rara_descricao"
        case entreEixosMm = "entre_eixos_mm"
        case comprimentoMm = "comprimento_mm"
        case composicao
        case designer
        case materialBancos = "material_bancos"
        case materialVolante = "material_volante"
        case interiorDestaque = "interior_destaque"
    }

    /// A tabela guarda a variante como 4 colunas soltas (nome/ano/valor/descrição),
    /// não como objeto aninhado — então o decode automático não monta
    /// `varianteMaisRara`. Decodificamos na mão a partir dessas colunas.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        modelo = try c.decode(String.self, forKey: .modelo)
        ano = try c.decodeIfPresent(Int.self, forKey: .ano)
        raridade = try c.decode(Int.self, forKey: .raridade)
        valorEstimadoUsd = try c.decode(Double.self, forKey: .valorEstimadoUsd)
        fotoUrl = try c.decode(String.self, forKey: .fotoUrl)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        motor = try c.decodeIfPresent(String.self, forKey: .motor)
        potenciaCv = try c.decodeIfPresent(Int.self, forKey: .potenciaCv)
        aceleracao0a100 = try c.decodeIfPresent(Double.self, forKey: .aceleracao0a100)
        velocidadeMaximaKmh = try c.decodeIfPresent(Int.self, forKey: .velocidadeMaximaKmh)
        pesoKg = try c.decodeIfPresent(Int.self, forKey: .pesoKg)
        producaoTotal = try c.decodeIfPresent(Int.self, forKey: .producaoTotal)
        analiseRaridade = try c.decodeIfPresent(String.self, forKey: .analiseRaridade)
        analiseMercado = try c.decodeIfPresent(String.self, forKey: .analiseMercado)
        serie = try c.decodeIfPresent(String.self, forKey: .serie)
        edicaoEspecial = try c.decodeIfPresent(String.self, forKey: .edicaoEspecial)
        entreEixosMm = try c.decodeIfPresent(Int.self, forKey: .entreEixosMm)
        comprimentoMm = try c.decodeIfPresent(Int.self, forKey: .comprimentoMm)
        composicao = try c.decodeIfPresent(String.self, forKey: .composicao)
        designer = try c.decodeIfPresent(String.self, forKey: .designer)
        materialBancos = try c.decodeIfPresent(String.self, forKey: .materialBancos)
        materialVolante = try c.decodeIfPresent(String.self, forKey: .materialVolante)
        interiorDestaque = try c.decodeIfPresent(String.self, forKey: .interiorDestaque)
        let varianteNome = try c.decodeIfPresent(String.self, forKey: .varianteMaisRaraNome)
        let varianteAno = try c.decodeIfPresent(Int.self, forKey: .varianteMaisRaraAno)
        let varianteValor = try c.decodeIfPresent(Double.self, forKey: .varianteMaisRaraValorUsd)
        let varianteDescricao = try c.decodeIfPresent(String.self, forKey: .varianteMaisRaraDescricao)
        if let varianteNome, let varianteAno, let varianteValor {
            varianteMaisRara = CarInfo.VarianteCarro(nome: varianteNome, ano: varianteAno, valorEstimadoUsd: varianteValor, descricao: varianteDescricao ?? "")
        } else {
            varianteMaisRara = nil
        }
    }

    init(
        id: UUID, modelo: String, ano: Int?, raridade: Int, valorEstimadoUsd: Double, fotoUrl: String, createdAt: Date,
        motor: String? = nil, potenciaCv: Int? = nil, aceleracao0a100: Double? = nil, velocidadeMaximaKmh: Int? = nil,
        pesoKg: Int? = nil, producaoTotal: Int? = nil, analiseRaridade: String? = nil, analiseMercado: String? = nil,
        serie: String? = nil, edicaoEspecial: String? = nil, varianteMaisRara: CarInfo.VarianteCarro? = nil,
        entreEixosMm: Int? = nil, comprimentoMm: Int? = nil, composicao: String? = nil, designer: String? = nil,
        materialBancos: String? = nil, materialVolante: String? = nil, interiorDestaque: String? = nil
    ) {
        self.id = id
        self.modelo = modelo
        self.ano = ano
        self.raridade = raridade
        self.valorEstimadoUsd = valorEstimadoUsd
        self.fotoUrl = fotoUrl
        self.createdAt = createdAt
        self.motor = motor
        self.potenciaCv = potenciaCv
        self.aceleracao0a100 = aceleracao0a100
        self.velocidadeMaximaKmh = velocidadeMaximaKmh
        self.pesoKg = pesoKg
        self.producaoTotal = producaoTotal
        self.analiseRaridade = analiseRaridade
        self.analiseMercado = analiseMercado
        self.serie = serie
        self.edicaoEspecial = edicaoEspecial
        self.varianteMaisRara = varianteMaisRara
        self.entreEixosMm = entreEixosMm
        self.comprimentoMm = comprimentoMm
        self.composicao = composicao
        self.designer = designer
        self.materialBancos = materialBancos
        self.materialVolante = materialVolante
        self.interiorDestaque = interiorDestaque
    }
}

struct SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://mevdvmjtkkcerkakzkch.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldmR2bWp0a2tjZXJrYWt6a2NoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4NDMwOTMsImV4cCI6MjEwMzQxOTA5M30.Cm36acvnAKTfjYjFMXX8ifyY849-goGnYrO9vQyEZP0"
    )

    /// Garante que existe uma sessão real antes de ler/escrever na wallet.
    /// Auth agora é obrigatório (email/senha ou Apple) — sem fallback anônimo.
    static func ensureSignedIn() throws {
        guard client.auth.currentSession != nil else {
            throw SupabaseError.notSignedIn
        }
    }

    static func uploadPhoto(imageData: Data) async throws -> String {
        try ensureSignedIn()
        let fileName = "\(UUID().uuidString).jpg"
        try await client.storage.from("car-photos").upload(fileName, data: imageData)
        return try client.storage.from("car-photos").getPublicURL(path: fileName).absoluteString
    }

    static func saveWalletItem(car: CarInfo, fotoUrl: String, lat: Double?, lng: Double?) async throws {
        try ensureSignedIn()
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notSignedIn
        }
        struct NewItem: Encodable {
            let user_id: UUID
            let modelo: String
            let ano: Int?
            let motor: String?
            let raridade: Int
            let valor_estimado_usd: Double
            let fato_interessante: String?
            let foto_url: String
            let lat: Double?
            let lng: Double?
            let potencia_cv: Int?
            let aceleracao_0_100: Double?
            let velocidade_maxima_kmh: Int?
            let peso_kg: Int?
            let producao_total: Int?
            let analise_raridade: String?
            let analise_mercado: String?
            let serie: String?
            let variante_mais_rara_nome: String?
            let variante_mais_rara_ano: Int?
            let variante_mais_rara_valor_usd: Double?
            let variante_mais_rara_descricao: String?
            let entre_eixos_mm: Int?
            let comprimento_mm: Int?
            let composicao: String?
            let designer: String?
            let material_bancos: String?
            let material_volante: String?
            let interior_destaque: String?
        }

        let item = NewItem(
            user_id: userId,
            modelo: car.modelo ?? "Desconhecido",
            ano: car.ano,
            motor: car.motor,
            raridade: car.raridade ?? 1,
            valor_estimado_usd: car.valorEstimadoUsd ?? 0,
            fato_interessante: car.fatoInteressante,
            foto_url: fotoUrl,
            lat: lat,
            lng: lng,
            potencia_cv: car.potenciaCv,
            aceleracao_0_100: car.aceleracao0a100,
            velocidade_maxima_kmh: car.velocidadeMaximaKmh,
            peso_kg: car.pesoKg,
            producao_total: car.producaoTotal,
            analise_raridade: car.analiseRaridade,
            analise_mercado: car.analiseMercado,
            serie: car.serie,
            variante_mais_rara_nome: car.varianteMaisRara?.nome,
            variante_mais_rara_ano: car.varianteMaisRara?.ano,
            variante_mais_rara_valor_usd: car.varianteMaisRara?.valorEstimadoUsd,
            variante_mais_rara_descricao: car.varianteMaisRara?.descricao,
            entre_eixos_mm: car.entreEixosMm,
            comprimento_mm: car.comprimentoMm,
            composicao: car.composicao,
            designer: car.designer,
            material_bancos: car.materialBancos,
            material_volante: car.materialVolante,
            interior_destaque: car.interiorDestaque
        )

        try await client.from("wallet_items").insert(item).execute()
    }

    static func fetchWalletItems() async throws -> [WalletItem] {
        try ensureSignedIn()
        return try await client.from("wallet_items")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    static func deleteWalletItems(ids: [UUID]) async throws {
        try ensureSignedIn()
        try await client.from("wallet_items")
            .delete()
            .in("id", values: ids.map(\.uuidString))
            .execute()
    }

    static func startOrFetchConversation(withUserId otherId: UUID) async throws -> UUID {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }
        guard otherId != myId else { throw SupabaseError.cannotMessageSelf }

        let userA = min(myId, otherId)
        let userB = max(myId, otherId)

        struct ConversationId: Decodable { let id: UUID }

        if let existing: ConversationId = try await client.from("conversations")
            .select("id")
            .eq("user_a", value: userA)
            .eq("user_b", value: userB)
            .maybeSingle()
            .execute()
            .value {
            return existing.id
        }

        struct NewConversation: Encodable {
            let user_a: UUID
            let user_b: UUID
        }
        let inserted: ConversationId = try await client.from("conversations")
            .insert(NewConversation(user_a: userA, user_b: userB))
            .select("id")
            .single()
            .execute()
            .value
        return inserted.id
    }

    static func fetchConversations() async throws -> [ConversationSummary] {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }

        struct ConversationRow: Decodable {
            let id: UUID
            let user_a: UUID
            let user_b: UUID
            let last_message_at: Date
        }

        let rows: [ConversationRow] = try await client.from("conversations")
            .select()
            .or("user_a.eq.\(myId),user_b.eq.\(myId)")
            .order("last_message_at", ascending: false)
            .execute()
            .value

        var summaries: [ConversationSummary] = []
        for row in rows {
            let otherId = row.user_a == myId ? row.user_b : row.user_a

            struct ProfileRow: Decodable {
                let username: String
                let avatar_url: String?
            }
            guard let profile: ProfileRow = try? await client.from("profiles")
                .select("username, avatar_url")
                .eq("id", value: otherId)
                .single()
                .execute()
                .value
            else { continue }

            struct LastMessageRow: Decodable { let text: String }
            // Conversa é criada (item "Mensagem" no perfil) antes de qualquer
            // mensagem existir — sem isso, uma conversa vazia (a pessoa
            // desistiu de mandar algo) aparece pra sempre na inbox dos dois.
            guard let lastMessage: LastMessageRow = try? await client.from("messages")
                .select("text")
                .eq("conversation_id", value: row.id)
                .order("created_at", ascending: false)
                .limit(1)
                .maybeSingle()
                .execute()
                .value
            else { continue }

            summaries.append(ConversationSummary(
                id: row.id, otherUserId: otherId, otherUsername: profile.username,
                otherAvatarUrl: profile.avatar_url, lastMessageText: lastMessage.text,
                lastMessageAt: row.last_message_at
            ))
        }
        return summaries
    }

    static func fetchMessages(conversationId: UUID) async throws -> [DBMessage] {
        try ensureSignedIn()
        return try await client.from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    static func sendMessage(conversationId: UUID, text: String) async throws {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }

        struct NewMessage: Encodable {
            let conversation_id: UUID
            let sender_id: UUID
            let text: String
        }
        // last_message_at é atualizado por trigger (touch_conversation, ver
        // migration 0007) — não há mais policy de UPDATE em conversations
        // pro client, então não fazemos esse update na mão aqui.
        try await client.from("messages")
            .insert(NewMessage(conversation_id: conversationId, sender_id: myId, text: text))
            .execute()
    }

    static func searchProfiles(username: String) async throws -> [SearchableUser] {
        try ensureSignedIn()
        struct ProfileRow: Decodable {
            let id: UUID
            let username: String
        }
        let rows: [ProfileRow] = try await client.from("profiles")
            .select("id, username")
            .ilike("username", pattern: "%\(username)%")
            .limit(20)
            .execute()
            .value
        return rows.map { SearchableUser(id: $0.id, username: $0.username) }
    }

    static func follow(userId: UUID) async throws {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }
        struct NewFollow: Encodable {
            let follower_id: UUID
            let following_id: UUID
        }
        do {
            try await client.from("follows")
                .insert(NewFollow(follower_id: myId, following_id: userId))
                .execute()
        } catch {
            // Já segue (duplicata na unique constraint) — não é erro de verdade pro usuário.
            if !error.localizedDescription.contains("duplicate key") {
                throw error
            }
        }
    }

    static func unfollow(userId: UUID) async throws {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }
        try await client.from("follows")
            .delete()
            .eq("follower_id", value: myId)
            .eq("following_id", value: userId)
            .execute()
    }

    static func isFollowing(userId: UUID) async throws -> Bool {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }
        struct FollowRow: Decodable { let follower_id: UUID }
        let rows: [FollowRow] = try await client.from("follows")
            .select("follower_id")
            .eq("follower_id", value: myId)
            .eq("following_id", value: userId)
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }

    /// Usa `count: .exact, head: true` pra pegar a contagem direto do Postgrest
    /// sem baixar as linhas — mais eficiente que buscar tudo e contar no cliente.
    static func followCounts(userId: UUID) async throws -> (followers: Int, following: Int) {
        try ensureSignedIn()
        let followersResponse = try await client.from("follows")
            .select("follower_id", head: true, count: .exact)
            .eq("following_id", value: userId)
            .execute()
        let followingResponse = try await client.from("follows")
            .select("following_id", head: true, count: .exact)
            .eq("follower_id", value: userId)
            .execute()
        return (followersResponse.count ?? 0, followingResponse.count ?? 0)
    }

    static func createPost(walletItemId: UUID?, modelo: String, raridade: Int, valorEstimadoUsd: Double, fotoUrl: String, caption: String?) async throws {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }
        struct NewPost: Encodable {
            let user_id: UUID
            let wallet_item_id: UUID?
            let modelo: String
            let raridade: Int
            let valor_estimado_usd: Double
            let foto_url: String
            let caption: String?
        }
        try await client.from("posts")
            .insert(NewPost(user_id: myId, wallet_item_id: walletItemId, modelo: modelo, raridade: raridade, valor_estimado_usd: valorEstimadoUsd, foto_url: fotoUrl, caption: caption))
            .execute()
    }

    static func fetchFeedPosts() async throws -> [DBPost] {
        try ensureSignedIn()
        let rows: [PostRow] = try await client.from("posts")
            .select()
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
        return try await resolvePosts(rows)
    }

    static func fetchPosts(userId: UUID) async throws -> [DBPost] {
        try ensureSignedIn()
        let rows: [PostRow] = try await client.from("posts")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return try await resolvePosts(rows)
    }

    private struct PostRow: Decodable {
        let id: UUID
        let user_id: UUID
        let modelo: String
        let raridade: Int
        let valor_estimado_usd: Double
        let foto_url: String
        let caption: String?
        let created_at: Date
    }

    private static func resolvePosts(_ rows: [PostRow]) async throws -> [DBPost] {
        let myId = client.auth.currentSession?.user.id

        var posts: [DBPost] = []
        for row in rows {
            struct ProfileRow: Decodable { let username: String; let avatar_url: String? }
            let profile: ProfileRow = (try? await client.from("profiles")
                .select("username, avatar_url")
                .eq("id", value: row.user_id)
                .single()
                .execute()
                .value) ?? ProfileRow(username: "usuário", avatar_url: nil)

            let likeCount: Int = (try? await client.from("likes")
                .select("post_id", head: true, count: .exact)
                .eq("post_id", value: row.id)
                .execute()
                .count) ?? 0

            let commentCount: Int = (try? await client.from("comments")
                .select("id", head: true, count: .exact)
                .eq("post_id", value: row.id)
                .execute()
                .count) ?? 0

            var likedByMe = false
            if let myId {
                struct LikeRow: Decodable { let user_id: UUID }
                let mine: [LikeRow] = (try? await client.from("likes")
                    .select("user_id")
                    .eq("post_id", value: row.id)
                    .eq("user_id", value: myId)
                    .limit(1)
                    .execute()
                    .value) ?? []
                likedByMe = !mine.isEmpty
            }

            posts.append(DBPost(
                id: row.id, userId: row.user_id, username: profile.username, avatarUrl: profile.avatar_url,
                modelo: row.modelo, raridade: row.raridade, valorEstimadoUsd: row.valor_estimado_usd,
                fotoUrl: row.foto_url, caption: row.caption, createdAt: row.created_at,
                likeCount: likeCount, commentCount: commentCount, likedByMe: likedByMe
            ))
        }
        return posts
    }

    static func toggleLike(postId: UUID) async throws -> Bool {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }

        struct LikeRow: Decodable { let user_id: UUID }
        let existing: [LikeRow] = try await client.from("likes")
            .select("user_id")
            .eq("post_id", value: postId)
            .eq("user_id", value: myId)
            .limit(1)
            .execute()
            .value

        if existing.isEmpty {
            struct NewLike: Encodable { let post_id: UUID; let user_id: UUID }
            do {
                try await client.from("likes")
                    .insert(NewLike(post_id: postId, user_id: myId))
                    .execute()
            } catch {
                // Double-tap gera PK duplicada — já está curtido, trata como sucesso.
                if !error.localizedDescription.contains("duplicate key") { throw error }
            }
            return true
        } else {
            try await client.from("likes")
                .delete()
                .eq("post_id", value: postId)
                .eq("user_id", value: myId)
                .execute()
            return false
        }
    }

    static func fetchComments(postId: UUID) async throws -> [DBComment] {
        try ensureSignedIn()
        struct CommentRow: Decodable {
            let id: UUID
            let post_id: UUID
            let user_id: UUID
            let text: String
            let created_at: Date
        }
        let rows: [CommentRow] = try await client.from("comments")
            .select()
            .eq("post_id", value: postId)
            .order("created_at", ascending: true)
            .execute()
            .value

        var comments: [DBComment] = []
        for row in rows {
            struct ProfileRow: Decodable { let username: String }
            let profile: ProfileRow = (try? await client.from("profiles")
                .select("username")
                .eq("id", value: row.user_id)
                .single()
                .execute()
                .value) ?? ProfileRow(username: "usuário")
            comments.append(DBComment(id: row.id, postId: row.post_id, userId: row.user_id, username: profile.username, text: row.text, createdAt: row.created_at))
        }
        return comments
    }

    static func addComment(postId: UUID, text: String) async throws {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }
        struct NewComment: Encodable {
            let post_id: UUID
            let user_id: UUID
            let text: String
        }
        try await client.from("comments")
            .insert(NewComment(post_id: postId, user_id: myId, text: text))
            .execute()
    }
}
