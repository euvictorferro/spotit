import CoreLocation

/// Metadados de marca — país de origem (pra Geographic Distribution) e
/// contagem aproximada de modelos conhecidos (denominador do "Sets").
/// É uma tabela estática por enquanto; dá pra virar dado real/API depois.
struct CarBrandInfo {
    let country: String
    let flag: String
    let coordinate: CLLocationCoordinate2D
    let knownModels: Int

    static let table: [String: CarBrandInfo] = [
        "Ferrari": .init(country: "Itália", flag: "🇮🇹", coordinate: .init(latitude: 44.53, longitude: 10.86), knownModels: 30),
        "Lamborghini": .init(country: "Itália", flag: "🇮🇹", coordinate: .init(latitude: 44.65, longitude: 11.14), knownModels: 15),
        "Pagani": .init(country: "Itália", flag: "🇮🇹", coordinate: .init(latitude: 44.75, longitude: 10.33), knownModels: 6),
        "Bugatti": .init(country: "França", flag: "🇫🇷", coordinate: .init(latitude: 48.55, longitude: 7.68), knownModels: 8),
        "Porsche": .init(country: "Alemanha", flag: "🇩🇪", coordinate: .init(latitude: 48.83, longitude: 9.15), knownModels: 25),
        "BMW": .init(country: "Alemanha", flag: "🇩🇪", coordinate: .init(latitude: 48.18, longitude: 11.56), knownModels: 25),
        "Audi": .init(country: "Alemanha", flag: "🇩🇪", coordinate: .init(latitude: 48.78, longitude: 11.43), knownModels: 20),
        "Mercedes-AMG": .init(country: "Alemanha", flag: "🇩🇪", coordinate: .init(latitude: 49.79, longitude: 8.68), knownModels: 25),
        "McLaren": .init(country: "Reino Unido", flag: "🇬🇧", coordinate: .init(latitude: 51.35, longitude: -0.55), knownModels: 20),
        "Aston Martin": .init(country: "Reino Unido", flag: "🇬🇧", coordinate: .init(latitude: 52.0, longitude: -0.65), knownModels: 15),
        "Rolls-Royce": .init(country: "Reino Unido", flag: "🇬🇧", coordinate: .init(latitude: 50.85, longitude: -0.55), knownModels: 10),
        "Koenigsegg": .init(country: "Suécia", flag: "🇸🇪", coordinate: .init(latitude: 56.30, longitude: 12.85), knownModels: 8),
        "Toyota": .init(country: "Japão", flag: "🇯🇵", coordinate: .init(latitude: 35.08, longitude: 137.16), knownModels: 40),
        "Nissan": .init(country: "Japão", flag: "🇯🇵", coordinate: .init(latitude: 35.44, longitude: 139.64), knownModels: 30),
        "Mazda": .init(country: "Japão", flag: "🇯🇵", coordinate: .init(latitude: 34.34, longitude: 132.55), knownModels: 15),
        "Lexus": .init(country: "Japão", flag: "🇯🇵", coordinate: .init(latitude: 35.08, longitude: 137.16), knownModels: 15),
        "Acura": .init(country: "Japão", flag: "🇯🇵", coordinate: .init(latitude: 34.35, longitude: 136.90), knownModels: 10),
        "Ford": .init(country: "EUA", flag: "🇺🇸", coordinate: .init(latitude: 42.33, longitude: -83.05), knownModels: 40),
        "Dodge": .init(country: "EUA", flag: "🇺🇸", coordinate: .init(latitude: 42.52, longitude: -83.03), knownModels: 15),
        "Chevrolet": .init(country: "EUA", flag: "🇺🇸", coordinate: .init(latitude: 42.60, longitude: -83.15), knownModels: 30),
    ]

    /// Extrai a marca do nome do modelo (ex: "Ferrari 488 Pista" → "Ferrari").
    /// Marcas de duas palavras (Mercedes-AMG, Aston Martin, Rolls-Royce)
    /// são checadas primeiro pra não cortar no meio.
    static func brand(for modelo: String) -> String {
        for key in table.keys where modelo.hasPrefix(key) {
            return key
        }
        return modelo.components(separatedBy: " ").first ?? modelo
    }

    static func info(for modelo: String) -> CarBrandInfo? {
        table[brand(for: modelo)]
    }
}
