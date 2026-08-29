import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [DBNotification] = []
    @State private var pushUserId: UUID?
    @State private var detailItem: WalletItem?

    private func section(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Hoje" }
        if calendar.isDateInYesterday(date) { return "Ontem" }
        if let days = calendar.dateComponents([.day], from: date, to: Date()).day, days < 7 { return "Esta Semana" }
        return "Mais Antigo"
    }

    private var sections: [String] {
        var seen = Set<String>()
        return notifications.map { section(for: $0.createdAt) }.filter { seen.insert($0).inserted }
    }

    private func notifications(in section: String) -> [DBNotification] {
        notifications.filter { self.section(for: $0.createdAt) == section }
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
                                    .onTapGesture { pushUserId = user.id }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Notificações")
        .task { await load() }
        .refreshable { await load() }
        .navigationDestination(item: $pushUserId) { userId in
            let user = actor(for: userId)
            UserProfileView(
                username: user.username,
                avatarInitials: user.avatarInitials,
                avatarColors: user.avatarColors,
                userId: userId
            )
        }
        .fullScreenCover(item: $detailItem) { item in
            CarDetailPageView(item: item)
        }
    }

    private func load() async {
        notifications = (try? await SupabaseService.fetchNotifications()) ?? []
    }

    private func actor(for userId: UUID) -> SearchableUser {
        if let notification = notifications.first(where: { $0.actorId == userId }) {
            return SearchableUser(id: userId, username: notification.actorUsername)
        }
        if let user = suggestions.first(where: { $0.id == userId }) { return user }
        return SearchableUser(id: userId, username: "")
    }

    private func text(for kind: NotificationKind) -> String {
        switch kind {
        case .like: return "curtiu seu post"
        case .comment: return "comentou no seu post"
        case .follow: return "começou a seguir você"
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func row(_ notification: DBNotification) -> some View {
        let actor = SearchableUser(id: notification.actorId, username: notification.actorUsername)
        return HStack(spacing: Theme.Spacing.sm) {
            if !notification.isRead {
                Circle().fill(Color.accentColor).frame(width: 7, height: 7)
            } else {
                Circle().fill(.clear).frame(width: 7, height: 7)
            }

            Circle()
                .fill(LinearGradient(colors: actor.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: icon(for: notification.kind))
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(color(for: notification.kind), in: Circle())
                        .offset(x: 13, y: 13)
                )
                .overlay(Text(actor.avatarInitials).font(.caption2).fontWeight(.bold).foregroundStyle(.white))

            (Text(notification.actorUsername).fontWeight(.semibold) + Text(" " + text(for: notification.kind)))
                .font(.subheadline)
                .foregroundStyle(notification.isRead ? .secondary : .primary)

            Spacer()

            Text(timeAgo(notification.createdAt))
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

    private func open(_ notification: DBNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
        Task { try? await SupabaseService.markNotificationRead(id: notification.id) }

        switch notification.kind {
        case .follow:
            pushUserId = notification.actorId
        case .like, .comment:
            guard let postId = notification.postId else { return }
            Task {
                if let post = (try? await SupabaseService.fetchFeedPosts())?.first(where: { $0.id == postId }) {
                    detailItem = WalletItem(dbPost: post)
                }
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
