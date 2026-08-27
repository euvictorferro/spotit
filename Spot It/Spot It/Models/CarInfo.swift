import Foundation

struct CarInfo: Codable {
    let reconhecido: Bool
    let modelo: String?
    let ano: Int?
    let motor: String?
    let raridade: Int?
    let valorEstimadoUsd: Double?
    let fatoInteressante: String?

    enum CodingKeys: String, CodingKey {
        case reconhecido
        case modelo
        case ano
        case motor
        case raridade
        case valorEstimadoUsd = "valor_estimado_usd"
        case fatoInteressante = "fato_interessante"
    }
}
