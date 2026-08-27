import SwiftUI

/// 20 carros de exemplo pra visualizar a Wallet cheia antes de termos dados
/// reais suficientes. Usado como fallback quando o Supabase ainda não tem
/// itens salvos (ver WalletView.load()).
extension WalletItem {
    private static func mock(_ modelo: String, _ ano: Int, _ raridade: Int, _ valor: Double, _ aceleracao: Double) -> WalletItem {
        WalletItem(id: UUID(), modelo: modelo, ano: ano, raridade: raridade, valorEstimadoUsd: valor, fotoUrl: "", createdAt: Date(), aceleracao0a100: aceleracao)
    }

    static let sample: [WalletItem] = [
        mock("Koenigsegg Jesko", 2023, 10, 3_000_000, 2.5),
        mock("Pagani Huayra", 2021, 10, 2_600_000, 2.8),
        mock("Ford GT", 2019, 9, 500_000, 3.0),
        mock("Lexus LFA", 2011, 9, 400_000, 3.7),
        mock("Mercedes-AMG GT Black Series", 2021, 9, 335_000, 3.1),
        mock("Nissan Skyline GT-R R34", 1999, 9, 250_000, 4.8),
        mock("Rolls-Royce Wraith Black Badge", 2022, 8, 360_000, 4.4),
        mock("Ferrari 488 Pista", 2019, 8, 370_000, 2.85),
        mock("Lamborghini Huracán STO", 2022, 8, 330_000, 3.0),
        mock("McLaren 720S", 2020, 7, 310_000, 2.9),
        mock("Porsche 911 Turbo S", 2022, 7, 230_000, 2.7),
        mock("Audi R8 V10", 2021, 7, 175_000, 3.2),
        mock("Dodge Viper ACR", 2017, 7, 120_000, 3.5),
        mock("Toyota Supra MK4 (2JZ)", 1998, 7, 85_000, 4.6),
        mock("Mazda RX-7 FD", 1996, 7, 65_000, 5.3),
        mock("Acura NSX", 2019, 6, 170_000, 2.9),
        mock("Nissan GT-R Nismo", 2021, 6, 215_000, 2.5),
        mock("Aston Martin Vantage", 2020, 6, 150_000, 3.5),
        mock("Chevrolet Corvette Z06", 2023, 6, 110_000, 2.6),
        mock("BMW M3 (E46)", 2004, 5, 45_000, 5.1),
    ]
}
