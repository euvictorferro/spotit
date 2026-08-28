import SwiftUI

struct NotificationsView: View {
    @State private var notifications = AppNotification.sample
    @State private var pushUsername: String?
    @State private var detailItem: WalletItem?

    private var sections: [String] {
        var seen = Set<String>()
        return notifications.map(\.section).filter { seen.insert($0).inserted }
    }

    private func notifications(in section: String) -> [AppNotification] {
        notifications.filter { $0.section == section }
    }

    var body: some View {
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
        }
        .navigationTitle("Notificações")
        .navigationDestination(item: $pushUsername) { username in
            UserProfileView(
                username: username,
                avatarInitials: notifications.first { $0.username == username }?.avatarInitials ?? "",
                avatarColors: notifications.first { $0.username == username }?.avatarColors ?? [.gray]
            )
        }
        .sheet(item: $detailItem) { item in
            CarDetailPageView(item: item)
        }
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

#Preview {
    NavigationStack { NotificationsView() }
}
