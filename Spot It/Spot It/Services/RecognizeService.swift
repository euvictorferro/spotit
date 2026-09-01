import Auth
import Foundation
import Supabase

enum RecognizeError: LocalizedError {
    case invalidResponse(statusCode: Int, body: String)
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let statusCode, let body):
            return "HTTP \(statusCode): \(body.prefix(200))"
        case .notSignedIn:
            return "Você precisa estar logado pra identificar um carro."
        }
    }
}

struct RecognizeService {
    static let baseURL = URL(string: "https://spotit-gamma.vercel.app")!

    static func recognize(imageData: Data) async throws -> CarInfo {
        try await recognize(imagesData: [imageData])
    }

    /// Aceita múltiplas fotos (ângulos diferentes do mesmo carro) — usado no
    /// fallback quando a 1ª foto sozinha não é reconhecida.
    ///
    /// `quick: true` pede só os 7 campos essenciais (resposta bem mais curta
    /// = scan mais rápido) — usado pra mostrar o resultado na hora, com o
    /// perfil completo (raridade, mercado, design etc) vindo depois numa 2ª
    /// chamada em background (`quick: false`).
    static func recognize(imagesData: [Data], quick: Bool = false) async throws -> CarInfo {
        // O endpoint exige um usuário autenticado (senão qualquer um na
        // internet gastava nosso orçamento de IA sem nem ter o app).
        guard let accessToken = SupabaseService.client.auth.currentSession?.accessToken else {
            throw RecognizeError.notSignedIn
        }

        struct RecognizeBody: Encodable {
            let images: [String]
            let quick: Bool
        }

        let images = imagesData.map { $0.base64EncodedString() }
        var request = URLRequest(url: baseURL.appendingPathComponent("api/recognize"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(RecognizeBody(images: images, quick: quick))
        // Vários ângulos + resposta longa podem passar do timeout padrão de
        // 60s do URLSession — a função no servidor já tem até 60s (vercel.json).
        request.timeoutInterval = 90

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "<sem corpo>"
            throw RecognizeError.invalidResponse(statusCode: statusCode, body: body)
        }

        return try JSONDecoder().decode(CarInfo.self, from: data)
    }
}
