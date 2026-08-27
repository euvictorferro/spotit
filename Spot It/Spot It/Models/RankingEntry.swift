import SwiftUI

struct RankingEntry: Identifiable {
    let id = UUID()
    let username: String
    let avatarColors: [Color]
    let avatarInitials: String
    let walletValueUsd: Double
    let isMe: Bool

    static let sample: [RankingEntry] = [
        RankingEntry(username: "motor_teresa", avatarColors: [.red, .orange], avatarInitials: "MT", walletValueUsd: 4_120_000, isMe: false),
        RankingEntry(username: "dudda.cars", avatarColors: [.pink, .purple], avatarInitials: "DC", walletValueUsd: 2_950_000, isMe: false),
        RankingEntry(username: "rk.spotter", avatarColors: [.purple, .indigo], avatarInitials: "RK", walletValueUsd: 1_780_000, isMe: false),
        RankingEntry(username: "victorferro", avatarColors: [.red, .black], avatarInitials: "VF", walletValueUsd: 780_000, isMe: true),
        RankingEntry(username: "jsilva_cars", avatarColors: [.blue, .cyan], avatarInitials: "JS", walletValueUsd: 512_000, isMe: false),
        RankingEntry(username: "lu.exotics", avatarColors: [.green, .mint], avatarInitials: "LE", walletValueUsd: 340_000, isMe: false),
    ]
}
