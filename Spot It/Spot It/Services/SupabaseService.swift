import Foundation
import Supabase

enum SupabaseError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        "Não autenticado — tenta de novo em alguns segundos."
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
        try await ensureSignedIn()
        return try await client.from("wallet_items")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    static func deleteWalletItems(ids: [UUID]) async throws {
        try await ensureSignedIn()
        try await client.from("wallet_items")
            .delete()
            .in("id", values: ids.map(\.uuidString))
            .execute()
    }
}
