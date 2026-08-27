import Foundation

enum NotificationKind {
    case like, comment, follow
}

struct AppNotification: Identifiable {
    let id = UUID()
    let kind: NotificationKind
    let username: String
    let text: String
    let timeAgo: String

    static let sample: [AppNotification] = [
        AppNotification(kind: .like, username: "dudda.cars", text: "curtiu sua foto do Bugatti Chiron", timeAgo: "5min"),
        AppNotification(kind: .comment, username: "carspotter_fl", text: "comentou: \"onde foi isso?\"", timeAgo: "20min"),
        AppNotification(kind: .follow, username: "lu.exotics", text: "começou a seguir você", timeAgo: "2h"),
        AppNotification(kind: .like, username: "rk.spotter", text: "curtiu sua foto do M4 Competition", timeAgo: "1d"),
    ]
}
