import SwiftUI

enum NotificationKind {
    case like, comment, follow
}

struct AppNotification: Identifiable {
    let id = UUID()
    let kind: NotificationKind
    let username: String
    let avatarColors: [Color]
    let text: String
    let timeAgo: String
    /// Agrupamento simples pra lista (Hoje/Ontem/Esta Semana) — quando vier
    /// do backend, isso vira um cálculo em cima de um timestamp real.
    let section: String
    var isRead: Bool = false
    /// Post relacionado (curtida/comentário) — usado pra abrir os detalhes
    /// do carro ao tocar na notificação. nil pras notificações de "seguiu você".
    let relatedPost: FeedPost?

    var avatarInitials: String {
        String(username.prefix(2)).uppercased()
    }

    static let sample: [AppNotification] = [
        AppNotification(kind: .like, username: "dudda.cars", avatarColors: [.pink, .purple], text: "curtiu sua foto do Bugatti Chiron", timeAgo: "5min", section: "Hoje", relatedPost: FeedPost.sample[0]),
        AppNotification(kind: .comment, username: "carspotter_fl", avatarColors: [.teal, .blue], text: "comentou: \"onde foi isso?\"", timeAgo: "20min", section: "Hoje", relatedPost: FeedPost.sample[1]),
        AppNotification(kind: .follow, username: "lu.exotics", avatarColors: [.green, .mint], text: "começou a seguir você", timeAgo: "2h", section: "Hoje", relatedPost: nil),
        AppNotification(kind: .like, username: "rk.spotter", avatarColors: [.purple, .indigo], text: "curtiu sua foto do GT3 RS", timeAgo: "1d", section: "Ontem", isRead: true, relatedPost: FeedPost.sample[1]),
    ]
}
