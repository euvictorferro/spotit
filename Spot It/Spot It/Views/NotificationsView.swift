import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [AppNotification] = []
    @State private var pushUsername: String?
    @State private var detailItem: WalletItem?

    private var sections: [String] {
        var seen = Set<String>()
        return notifications.map(\.section).filter { seen.insert($0).inserted }
    }

    private func notifications(in section: String) -> [AppNotification] {
        notifications.filter { $0.section == section }
    }

    /// Pessoas que já te seguem mas você ainda não segue de volta — some até
    /// ter grafo social real ("followers not followed back").
    private let suggestions: [SearchableUser] = []

    var body: some View {
        Group {
            if notifications.isEmpty && suggestions.isEmpty {
                EmptyStateView(icon: "bell", message: "Nenhuma notificação ainda.")
            } else {
                List {
                    ForEach(sections, id: \.self) { section in
                        Section(section) {
                            ForEach(notifications(in: section)) { notification in
                                row(notification)
                                    .contentShape(Rectangle())
                                    .onTapGesture { open(notification) }
                            }
                        }
                    }

                    if !suggestions.isEmpty {
                        Section("Sugestões para seguir de volta") {
                            ForEach(suggestions) { user in
                                suggestionRow(user)
                                    .contentShape(Rectangle())
                                    .onTapGesture { pushUsername = user.username }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Notificações")
        .navigationDestination(item: $pushUsername) { username in
            // ponytail: Notificações ainda não tem backend real — sem userId real até então.
            UserProfileView(
                username: username,
                avatarInitials: avatarInitials(for: username),
                avatarColors: avatarColors(for: username),
                userId: UUID()
            )
        }
        .fullScreenCover(item: $detailItem) { item in
            CarDetailPageView(item: item)
        }
    }

    private func avatarInitials(for username: String) -> String {
        notifications.first { $0.username == username }?.avatarInitials
            ?? suggestions.first { $0.username == username }?.avatarInitials ?? ""
    }

    private func avatarColors(for username: String) -> [Color] {
        notifications.first { $0.username == username }?.avatarColors
            ?? suggestions.first { $0.username == username }?.avatarColors ?? [.gray]
    }

    private func row(_ notification: AppNotification) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            if !notification.isRead {
                Circle().fill(Color.accentColor).frame(width: 7, height: 7)
            } else {
                Circle().fill(.clear).frame(width: 7, height: 7)
            }

            Circle()
                .fill(LinearGradient(colors: notification.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: icon(for: notification.kind))
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(color(for: notification.kind), in: Circle())
                        .offset(x: 13, y: 13)
                )
                .overlay(Text(notification.avatarInitials).font(.caption2).fontWeight(.bold).foregroundStyle(.white))

            (Text(notification.username).fontWeight(.semibold) + Text(" " + notification.text))
                .font(.subheadline)
                .foregroundStyle(notification.isRead ? .secondary : .primary)

            Spacer()

            Text(notification.timeAgo)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func suggestionRow(_ user: SearchableUser) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(LinearGradient(colors: user.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 38, height: 38)
                .overlay(Text(user.avatarInitials).font(.caption2).fontWeight(.bold).foregroundStyle(.white))

            VStack(alignment: .leading, spacing: 1) {
                Text(user.username).font(.subheadline).fontWeight(.semibold)
                Text("Segue você").font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            SuggestionFollowButton()
        }
        .padding(.vertical, 2)
    }

    private func open(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
        switch notification.kind {
        case .follow:
            pushUsername = notification.username
        case .like, .comment:
            if let post = notification.relatedPost {
                detailItem = WalletItem(feedPost: post)
            }
        }
    }

    private func icon(for kind: NotificationKind) -> String {
        switch kind {
        case .like: return "heart.fill"
        case .comment: return "message.fill"
        case .follow: return "person.fill.badge.plus"
        }
    }

    private func color(for kind: NotificationKind) -> Color {
        switch kind {
        case .like: return .red
        case .comment: return .blue
        case .follow: return Color.accentColor
        }
    }
}

/// Botão "Seguir" → "Seguindo" com estado local, mesmo padrão do FollowButton
/// do feed — some é o card de sugestão que fica, então não precisa sumir.
private struct SuggestionFollowButton: View {
    @State private var isFollowing = false

    var body: some View {
        Button {
            isFollowing.toggle()
        } label: {
            Text(isFollowing ? "Seguindo" : "Seguir")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 6)
                .background(isFollowing ? Color(.secondarySystemBackground) : Color.accentColor, in: Capsule())
                .foregroundStyle(isFollowing ? Color.primary : Color.white)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { NotificationsView() }
}
