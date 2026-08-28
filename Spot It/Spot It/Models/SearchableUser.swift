import SwiftUI

/// Diretório de usuários pra busca — hoje é a união dos usernames que já
/// aparecem no Feed/Ranking/DM (mock). Vira uma tabela de usuários real do
/// Supabase quando tivermos auth e cadastro de perfil.
struct SearchableUser: Identifiable {
    let id = UUID()
    let username: String
    let avatarInitials: String
    let avatarColors: [Color]

    static let sample: [SearchableUser] = [
        SearchableUser(username: "motor_teresa", avatarInitials: "MT", avatarColors: [.red, .orange]),
        SearchableUser(username: "rk.spotter", avatarInitials: "RK", avatarColors: [.purple, .indigo]),
        SearchableUser(username: "jsilva_cars", avatarInitials: "JS", avatarColors: [.blue, .cyan]),
        SearchableUser(username: "dudda.cars", avatarInitials: "DC", avatarColors: [.pink, .purple]),
        SearchableUser(username: "lu.exotics", avatarInitials: "LE", avatarColors: [.green, .mint]),
        SearchableUser(username: "carspotter_fl", avatarInitials: "CF", avatarColors: [.teal, .blue]),
    ]
}
