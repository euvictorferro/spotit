import SwiftUI

/// 20 carros de exemplo pra visualizar a Wallet cheia antes de termos dados
/// reais suficientes. Usado como fallback quando o Supabase ainda não tem
/// itens salvos (ver WalletView.load()). Os principais têm o perfil
/// completo (specs, análises, variante mais rara, interior); os demais têm
/// um perfil mais enxuto — como aconteceria com dados reais da IA.
extension WalletItem {
    private static func mock(
        _ modelo: String, _ ano: Int, _ raridade: Int, _ valor: Double, _ aceleracao: Double,
        edicao: String? = nil, motor: String? = nil, potenciaCv: Int? = nil,
        velocidadeMaximaKmh: Int? = nil, pesoKg: Int? = nil, producaoTotal: Int? = nil,
        analiseRaridade: String? = nil, analiseMercado: String? = nil, serie: String? = nil,
        varianteMaisRara: CarInfo.VarianteCarro? = nil, entreEixosMm: Int? = nil,
        comprimentoMm: Int? = nil, composicao: String? = nil, designer: String? = nil,
        materialBancos: String? = nil, materialVolante: String? = nil, interiorDestaque: String? = nil
    ) -> WalletItem {
        WalletItem(
            id: UUID(), modelo: modelo, ano: ano, raridade: raridade, valorEstimadoUsd: valor, fotoUrl: "", createdAt: Date(),
            motor: motor, potenciaCv: potenciaCv, aceleracao0a100: aceleracao, velocidadeMaximaKmh: velocidadeMaximaKmh,
            pesoKg: pesoKg, producaoTotal: producaoTotal, analiseRaridade: analiseRaridade, analiseMercado: analiseMercado,
            serie: serie, edicaoEspecial: edicao, varianteMaisRara: varianteMaisRara, entreEixosMm: entreEixosMm,
            comprimentoMm: comprimentoMm, composicao: composicao, designer: designer,
            materialBancos: materialBancos, materialVolante: materialVolante, interiorDestaque: interiorDestaque
        )
    }

    static let sample: [WalletItem] = [
        mock(
            "Koenigsegg Jesko", 2023, 10, 3_000_000, 2.5,
            motor: "5.0L V8 Twin-Turbo Flat-Plane", potenciaCv: 1600, velocidadeMaximaKmh: 480, pesoKg: 1420,
            producaoTotal: 125,
            analiseRaridade: "Produção limitada a apenas 125 unidades ao longo de toda a vida do modelo, cada uma customizada individualmente pelo cliente na fábrica sueca. Isso torna cada Jesko praticamente uma peça única.",
            analiseMercado: "A demanda supera muito a oferta — a lista de espera já estava esgotada antes da produção terminar. Colecionadores pagam ágio significativo sobre o preço de fábrica em revendas.",
            serie: "Jesko",
            varianteMaisRara: .init(nome: "Jesko Absolut", ano: 2023, valorEstimadoUsd: 3_400_000, descricao: "Versão focada em velocidade máxima pura, sem asas ou aerofólios — projetada teoricamente pra ultrapassar 500 km/h."),
            entreEixosMm: 2665, comprimentoMm: 4610,
            composicao: "Monocoque em fibra de carbono, painéis externos em fibra de carbono",
            designer: "Christian von Koenigsegg",
            materialBancos: "Couro premium com costura customizável",
            materialVolante: "Fibra de carbono com alcantara",
            interiorDestaque: "Central multimídia com tela curva e sistema de câmbio 'Light Speed Transmission' de 9 embreagens, único no mercado."
        ),
        mock(
            "Pagani Huayra", 2021, 10, 2_600_000, 2.8,
            motor: "6.0L V12 Twin-Turbo (Mercedes-AMG)", potenciaCv: 730, velocidadeMaximaKmh: 383, pesoKg: 1350,
            producaoTotal: 100,
            analiseRaridade: "Cada Huayra leva meses pra ser montado à mão na oficina da Pagani na Itália. A produção é intencionalmente pequena pra manter a exclusividade da marca.",
            analiseMercado: "Peças Pagani raramente perdem valor — muitos exemplares já vendem acima do preço de lançamento, especialmente as edições especiais.",
            serie: "Huayra",
            entreEixosMm: 2795, comprimentoMm: 4605,
            composicao: "Carbo-Titanium (fibra de carbono + titânio) no monocoque",
            designer: "Horacio Pagani",
            materialBancos: "Couro artesanal costurado à mão",
            materialVolante: "Alumínio usinado com couro"
        ),
        mock(
            "Ford GT", 2019, 9, 500_000, 3.0,
            motor: "3.5L V6 EcoBoost Twin-Turbo", potenciaCv: 660, velocidadeMaximaKmh: 348, pesoKg: 1385,
            producaoTotal: 1350,
            analiseRaridade: "A Ford limitou a produção e exigiu que compradores fossem aprovados num processo seletivo — muitos pedidos foram recusados, o que aumentou o desejo pelo carro.",
            analiseMercado: "Exemplares em baixa quilometragem valorizaram bem acima do preço de tabela nos primeiros anos após o lançamento.",
            serie: "GT",
            entreEixosMm: 2710, comprimentoMm: 4676
        ),
        mock(
            "Lexus LFA", 2011, 9, 400_000, 3.7,
            motor: "4.8L V10 Aspirado", potenciaCv: 553, velocidadeMaximaKmh: 325, pesoKg: 1480,
            producaoTotal: 500,
            analiseRaridade: "A Toyota/Lexus produziu só 500 unidades e vendeu no prejuízo — cada carro custou mais pra fabricar do que o preço de venda, tornando reedições improváveis.",
            analiseMercado: "Um dos V10 mais icônicos já feitos; o som do motor é considerado obra de arte por entusiastas, o que sustenta valorização constante.",
            serie: "LFA"
        ),
        mock(
            "Mercedes-AMG GT Black Series", 2021, 9, 335_000, 3.1,
            edicao: "Brabus", motor: "4.0L V8 Twin-Turbo", potenciaCv: 730, velocidadeMaximaKmh: 325, pesoKg: 1595,
            producaoTotal: nil,
            analiseRaridade: "É a versão mais extrema já feita do AMG GT, com produção anual limitada e vendida rapidamente entre clientes fiéis da marca.",
            analiseMercado: "Alta demanda de colecionadores de AMG; versões Black Series historicamente valorizam depois que a produção encerra.",
            serie: "AMG"
        ),
        mock(
            "Nissan Skyline GT-R R34", 1999, 9, 250_000, 4.8,
            edicao: "Liberty Walk", motor: "2.6L RB26DETT Twin-Turbo", potenciaCv: 280, velocidadeMaximaKmh: 250, pesoKg: 1560,
            producaoTotal: nil,
            analiseRaridade: "Nunca foi vendido oficialmente nos EUA, o que criou uma corrida de importação assim que completou 25 anos — a raridade vem da combinação de idade, lenda cultural (Fast & Furious) e restrição de importação.",
            analiseMercado: "Um dos JDMs mais valorizados do mundo; preços triplicaram na última década conforme mais unidades ficam elegíveis pra importação nos EUA.",
            serie: "GT-R"
        ),
        mock(
            "Rolls-Royce Wraith Black Badge", 2022, 8, 360_000, 4.4,
            edicao: "Mansory", motor: "6.6L V12 Twin-Turbo", potenciaCv: 632, velocidadeMaximaKmh: 250, pesoKg: 2435,
            serie: "Black Badge"
        ),
        mock(
            "Ferrari 488 Pista", 2019, 8, 370_000, 2.85,
            motor: "3.9L V8 Twin-Turbo", potenciaCv: 720, velocidadeMaximaKmh: 340, pesoKg: 1385,
            producaoTotal: nil,
            analiseRaridade: "Versão de pista do 488, com alocação de produção controlada pela Ferrari pra clientes selecionados — não é vendido livremente.",
            analiseMercado: "Ferraris de edição de pista raramente desvalorizam; a demanda de colecionadores é constante.",
            serie: "Pista",
            varianteMaisRara: .init(nome: "488 Pista Piloti Ferrari", ano: 2019, valorEstimadoUsd: 520_000, descricao: "Edição especial em homenagem aos pilotos da Ferrari, com apenas algumas dezenas de unidades e itens exclusivos em fibra de carbono.")
        ),
        mock(
            "Lamborghini Huracán STO", 2022, 8, 330_000, 3.0,
            edicao: "Mansory", motor: "5.2L V10 Aspirado", potenciaCv: 640, velocidadeMaximaKmh: 310, pesoKg: 1339,
            producaoTotal: nil,
            analiseRaridade: "STO significa 'Super Trofeo Omologata' — é a versão de rua mais próxima do carro de corrida da Lamborghini, com produção anual limitada.",
            analiseMercado: "Alta procura entre entusiastas de track day; a versão preparada pela Mansory eleva ainda mais a exclusividade e o valor.",
            serie: "STO",
            varianteMaisRara: .init(nome: "Huracán STO Mansory", ano: 2022, valorEstimadoUsd: 480_000, descricao: "Kit de carroceria widebody exclusivo, rodas forjadas e escape customizado — cada unidade Mansory é praticamente única.")
        ),
        mock(
            "McLaren 720S", 2020, 7, 310_000, 2.9,
            edicao: "Novitec", motor: "4.0L V8 Twin-Turbo", potenciaCv: 720, velocidadeMaximaKmh: 341, pesoKg: 1283,
            serie: "720S"
        ),
        mock(
            "Porsche 911 Turbo S", 2022, 7, 230_000, 2.7,
            motor: "3.8L Flat-6 Twin-Turbo", potenciaCv: 650, velocidadeMaximaKmh: 330, pesoKg: 1640,
            producaoTotal: nil,
            analiseRaridade: "Não é tão limitado quanto hipercarros, mas o Turbo S é a versão mais exclusiva vendida do 911 — poucos concessionários recebem alocação por ano.",
            analiseMercado: "O 911 é historicamente o supercarro mais fácil de manter valor de revenda por causa da confiabilidade e legado da marca.",
            serie: "Turbo S",
            entreEixosMm: 2450, comprimentoMm: 4535,
            composicao: "Estrutura em aço e alumínio, capô e para-choques em plástico reforçado",
            designer: "Porsche Style (Michael Mauer)",
            materialBancos: "Couro esportivo com aquecimento e ventilação",
            materialVolante: "Couro perfurado com paddle shifts em alumínio",
            interiorDestaque: "Painel digital totalmente configurável de 12,6 polegadas e Porsche Communication Management com tela de 10,9 polegadas."
        ),
        mock("Audi R8 V10", 2021, 7, 175_000, 3.2, motor: "5.2L V10 Aspirado", potenciaCv: 620, velocidadeMaximaKmh: 331, pesoKg: 1595, serie: "R8"),
        mock("Dodge Viper ACR", 2017, 7, 120_000, 3.5, motor: "8.4L V10 Aspirado", potenciaCv: 645, velocidadeMaximaKmh: 285, pesoKg: 1550, producaoTotal: 500, serie: "ACR"),
        mock(
            "Toyota Supra MK4 (2JZ)", 1998, 7, 85_000, 4.6,
            motor: "3.0L 2JZ-GTE Twin-Turbo", potenciaCv: 320, velocidadeMaximaKmh: 285, pesoKg: 1590,
            analiseRaridade: "O motor 2JZ é lendário por aguentar potências muito acima da fábrica sem modificação interna — isso fez o carro virar ícone do tuning, elevando a demanda por exemplares originais bem conservados.",
            analiseMercado: "Preços dispararam na última década, impulsionados por nostalgia, cultura JDM e aparições no cinema.",
            serie: "MK4"
        ),
        mock("Mazda RX-7 FD", 1996, 7, 65_000, 5.3, motor: "1.3L Rotativo Twin-Turbo (13B-REW)", potenciaCv: 276, pesoKg: 1300, serie: "FD"),
        mock("Acura NSX", 2019, 6, 170_000, 2.9, motor: "3.5L V6 Twin-Turbo Híbrido", potenciaCv: 573, pesoKg: 1725, serie: "NSX"),
        mock("Nissan GT-R Nismo", 2021, 6, 215_000, 2.5, motor: "3.8L V6 Twin-Turbo", potenciaCv: 600, velocidadeMaximaKmh: 315, pesoKg: 1720, serie: "Nismo"),
        mock("Aston Martin Vantage", 2020, 6, 150_000, 3.5, motor: "4.0L V8 Twin-Turbo (AMG)", potenciaCv: 503, pesoKg: 1530, serie: "Vantage"),
        mock("Chevrolet Corvette Z06", 2023, 6, 110_000, 2.6, motor: "5.5L V8 Aspirado Flat-Plane", potenciaCv: 670, velocidadeMaximaKmh: 315, pesoKg: 1560, serie: "Z06"),
        mock("BMW M3 (E46)", 2004, 5, 45_000, 5.1, motor: "3.2L Reto-6 Aspirado (S54)", potenciaCv: 343, pesoKg: 1495, serie: "M3"),
    ]
}
