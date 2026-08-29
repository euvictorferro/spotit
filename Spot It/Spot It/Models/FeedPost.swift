import SwiftUI

/// Post do feed social. Por enquanto é preenchido com dados de exemplo — vira
/// real quando o Feed for conectado ao backend (ver Perfil/Auth real no roadmap).
struct FeedPost: Identifiable {
    let id = UUID()
    let username: String
    let avatarInitials: String
    let avatarColors: [Color]
    let location: String
    let timeAgo: String
    let photoGradient: [Color]
    let raridade: Int
    let isFollowing: Bool
    let valorEstimadoUsd: Double
    let likedByUsername: String
    let caption: String

    // Detalhes completos — só aparecem ao tocar no ícone de info, não no feed.
    let modelo: String
    let ano: Int
    let motor: String
    let fatoInteressante: String

    static let sample: [FeedPost] = [
        FeedPost(
            username: "motor_teresa",
            avatarInitials: "MT",
            avatarColors: [Color(red: 1, green: 0.18, blue: 0.15), Color(red: 0.72, green: 0.08, blue: 0.05)],
            location: "Naples, FL",
            timeAgo: "há 2h",
            photoGradient: [Color(red: 0.23, green: 0.16, blue: 0.02), Color(red: 0.06, green: 0.04, blue: 0.01)],
            raridade: 10,
            isFollowing: false,
            valorEstimadoUsd: 2_700_000,
            likedByUsername: "dudda.cars",
            caption: "achei no meio do posto tarde da noite, não acreditei 😭",
            modelo: "Bugatti Chiron Super Sport",
            ano: 2022,
            motor: "8.0L W16 Quad-Turbo, 1.578 cv",
            fatoInteressante: "Apenas 30 unidades produzidas — um dos carros de rua mais rápidos já feitos."
        ),
        FeedPost(
            username: "rk.spotter",
            avatarInitials: "RK",
            avatarColors: [Color(red: 0.75, green: 0.35, blue: 0.95), Color(red: 0.43, green: 0.12, blue: 0.57)],
            location: "Miami, FL",
            timeAgo: "há 5h",
            photoGradient: [Color(red: 0.14, green: 0.06, blue: 0.19), Color(red: 0.04, green: 0.03, blue: 0.06)],
            raridade: 8,
            isFollowing: false,
            valorEstimadoUsd: 223_000,
            likedByUsername: "lu.exotics",
            caption: "track day pack completo, aquele wing gigante",
            modelo: "Porsche 911 GT3 RS",
            ano: 2023,
            motor: "4.0L Flat-6 Aspirado, 518 cv",
            fatoInteressante: "O pacote aerodinâmico gera mais downforce que um GT3 de corrida da geração anterior."
        ),
        FeedPost(
            username: "jsilva_cars",
            avatarInitials: "JS",
            avatarColors: [Color(red: 0.04, green: 0.52, blue: 1), Color(red: 0.02, green: 0.32, blue: 0.65)],
            location: "Orlando, FL",
            timeAgo: "há 1d",
            photoGradient: [Color(red: 0.05, green: 0.12, blue: 0.2), Color(red: 0.02, green: 0.04, blue: 0.07)],
            raridade: 5,
            isFollowing: true,
            valorEstimadoUsd: 78_500,
            likedByUsername: "victorferro",
            caption: "Isle of Man Green fica melhor pessoalmente",
            modelo: "BMW M4 Competition",
            ano: 2023,
            motor: "3.0L Reto-6 Twin-Turbo, 503 cv",
            fatoInteressante: "A cor Isle of Man Green é uma homenagem ao M3 original dos anos 90."
        ),
    ]
}

extension WalletItem {
    /// Converte um post do feed pra abrir a mesma CarDetailPageView usada na Wallet.
    /// Campos que o feed não tem (specs avançadas, série, interior) ficam nil —
    /// a página já trata seções opcionais como ausentes.
    init(feedPost post: FeedPost) {
        self.init(modelo: post.modelo, ano: post.ano, raridade: post.raridade, valorEstimadoUsd: post.valorEstimadoUsd, motor: post.motor, fatoInteressante: post.fatoInteressante)
    }

    /// Converte um post real (DBPost) pra abrir a mesma CarDetailPageView da
    /// Wallet. DBPost não tem ano/motor/fato interessante — ficam nil, a
    /// página já trata seções opcionais como ausentes.
    init(dbPost post: DBPost) {
        id = post.id
        modelo = post.modelo
        ano = nil
        raridade = post.raridade
        valorEstimadoUsd = post.valorEstimadoUsd
        fotoUrl = post.fotoUrl
        createdAt = post.createdAt
        motor = nil
        potenciaCv = nil
        aceleracao0a100 = nil
        velocidadeMaximaKmh = nil
        pesoKg = nil
        producaoTotal = nil
        analiseRaridade = nil
        analiseMercado = nil
        serie = nil
        edicaoEspecial = nil
        varianteMaisRara = nil
        entreEixosMm = nil
        comprimentoMm = nil
        composicao = nil
        designer = nil
        materialBancos = nil
        materialVolante = nil
        interiorDestaque = nil
    }

    /// Init "raso" usado por qualquer tela que só tem os dados básicos do
    /// carro (feed, mapa) e quer abrir a mesma CarDetailPageView da Wallet.
    init(modelo: String, ano: Int, raridade: Int, valorEstimadoUsd: Double, motor: String, fatoInteressante: String) {
        id = UUID()
        self.modelo = modelo
        self.ano = ano
        self.raridade = raridade
        self.valorEstimadoUsd = valorEstimadoUsd
        fotoUrl = ""
        createdAt = Date()
        self.motor = motor
        potenciaCv = nil
        aceleracao0a100 = nil
        velocidadeMaximaKmh = nil
        pesoKg = nil
        producaoTotal = nil
        analiseRaridade = nil
        analiseMercado = fatoInteressante
        serie = nil
        edicaoEspecial = nil
        varianteMaisRara = nil
        entreEixosMm = nil
        comprimentoMm = nil
        composicao = nil
        designer = nil
        materialBancos = nil
        materialVolante = nil
        interiorDestaque = nil
    }
}
