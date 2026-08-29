import SwiftUI

/// Resultado de busca — construído a partir de `profiles` real
/// (SupabaseService.searchProfiles). `id` é o user_id de verdade, não
/// gerado localmente — precisa bater com auth.uid() em RLS/DM.
struct SearchableUser: Identifiable {
    let id: UUID
    let username: String
    let avatarInitials: String
    let avatarColors: [Color]

    /// Sem cor de avatar salva no backend — deriva 2 cores determinísticas
    /// a partir do hash do username, pra cada pessoa ter uma cor estável
    /// (não muda a cada busca) sem precisar de coluna nova.
    init(id: UUID, username: String) {
        self.id = id
        self.username = username
        let parts = username.split(separator: "_").flatMap { $0.split(separator: ".") }
        let initials = parts.compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased()
        self.avatarInitials = initials.isEmpty ? String(username.prefix(2)).uppercased() : initials

        let palette: [[Color]] = [
            [.red, .orange], [.purple, .indigo], [.blue, .cyan],
            [.pink, .purple], [.green, .mint], [.teal, .blue],
        ]
        let index = abs(username.hashValue) % palette.count
        self.avatarColors = palette[index]
    }
}
