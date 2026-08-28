import Foundation

struct CarInfo: Codable {
    let reconhecido: Bool
    let modelo: String?
    let ano: Int?
    let motor: String?
    let raridade: Int?
    let valorEstimadoUsd: Double?
    let fatoInteressante: String?

    let potenciaCv: Int?
    let aceleracao0a100: Double?
    let velocidadeMaximaKmh: Int?
    let pesoKg: Int?
    let paisOrigem: String?
    let producaoTotal: Int?

    let analiseRaridade: String?
    let analiseMercado: String?

    let designExterior: String?
    let designInterior: String?

    let varianteEspecial: VarianteCarro?

    let serie: String?
    let varianteMaisRara: VarianteCarro?

    let entreEixosMm: Int?
    let comprimentoMm: Int?
    let composicao: String?
    let designer: String?

    let materialBancos: String?
    let materialVolante: String?
    let interiorDestaque: String?

    struct VarianteCarro: Codable {
        let nome: String
        let ano: Int
        let valorEstimadoUsd: Double
        let descricao: String

        enum CodingKeys: String, CodingKey {
            case nome, ano
            case valorEstimadoUsd = "valor_estimado_usd"
            case descricao
        }
    }

    enum CodingKeys: String, CodingKey {
        case reconhecido
        case modelo
        case ano
        case motor
        case raridade
        case valorEstimadoUsd = "valor_estimado_usd"
        case fatoInteressante = "fato_interessante"
        case potenciaCv = "potencia_cv"
        case aceleracao0a100 = "aceleracao_0_100"
        case velocidadeMaximaKmh = "velocidade_maxima_kmh"
        case pesoKg = "peso_kg"
        case paisOrigem = "pais_origem"
        case producaoTotal = "producao_total"
        case analiseRaridade = "analise_raridade"
        case analiseMercado = "analise_mercado"
        case designExterior = "design_exterior"
        case designInterior = "design_interior"
        case varianteEspecial = "variante_especial"
        case serie
        case varianteMaisRara = "variante_mais_rara"
        case entreEixosMm = "entre_eixos_mm"
        case comprimentoMm = "comprimento_mm"
        case composicao
        case designer
        case materialBancos = "material_bancos"
        case materialVolante = "material_volante"
        case interiorDestaque = "interior_destaque"
    }
}
