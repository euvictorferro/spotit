import Foundation

enum RecognizeError: LocalizedError {
    case invalidResponse(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let statusCode, let body):
            return "HTTP \(statusCode): \(body.prefix(200))"
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
    static func recognize(imagesData: [Data]) async throws -> CarInfo {
        let images = imagesData.map { $0.base64EncodedString() }
        var request = URLRequest(url: baseURL.appendingPathComponent("api/recognize"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["images": images])
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
