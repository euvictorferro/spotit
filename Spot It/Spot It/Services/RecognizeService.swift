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
        let base64 = imageData.base64EncodedString()
        var request = URLRequest(url: baseURL.appendingPathComponent("api/recognize"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["imageBase64": base64])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "<sem corpo>"
            throw RecognizeError.invalidResponse(statusCode: statusCode, body: body)
        }

        return try JSONDecoder().decode(CarInfo.self, from: data)
    }
}
