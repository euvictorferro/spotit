import SwiftUI

struct NotificationsView: View {
    var body: some View {
        List(AppNotification.sample) { notification in
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon(for: notification.kind))
                    .foregroundStyle(color(for: notification.kind))
                    .frame(width: 24)

                (Text(notification.username).fontWeight(.semibold) + Text(" " + notification.text))
                    .font(.subheadline)

                Spacer()

                Text(notification.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
        }
        .navigationTitle("Notificações")
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
