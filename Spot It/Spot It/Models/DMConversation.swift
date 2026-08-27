import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let fromMe: Bool
    let text: String
}

struct DMConversation: Identifiable {
    let id = UUID()
    let username: String
    let avatarColors: [Color]
    let avatarInitials: String
    let lastMessage: String
    let timeAgo: String
    var messages: [ChatMessage]

    static let sample: [DMConversation] = [
        DMConversation(
            username: "dudda.cars",
            avatarColors: [.red, .orange],
            avatarInitials: "DC",
            lastMessage: "esse chiron é seu mesmo?? 😱",
            timeAgo: "2min",
            messages: [
                ChatMessage(fromMe: false, text: "esse chiron é seu mesmo?? 😱"),
                ChatMessage(fromMe: true, text: "kkkk não, achei ele num posto"),
                ChatMessage(fromMe: false, text: "cara que sorte, nunca vi um de perto"),
            ]
        ),
        DMConversation(
            username: "rk.spotter",
            avatarColors: [.purple, Color(red: 0.43, green: 0.12, blue: 0.57)],
            avatarInitials: "RK",
            lastMessage: "bora no encontro sábado?",
            timeAgo: "1h",
            messages: [
                ChatMessage(fromMe: false, text: "bora no encontro sábado?"),
            ]
        ),
        DMConversation(
            username: "jsilva_cars",
            avatarColors: [.blue, Color(red: 0.02, green: 0.32, blue: 0.65)],
            avatarInitials: "JS",
            lastMessage: "Você: valeu!",
            timeAgo: "1d",
            messages: [
                ChatMessage(fromMe: false, text: "gostei do M4 que você postou"),
                ChatMessage(fromMe: true, text: "valeu!"),
            ]
        ),
    ]
}
