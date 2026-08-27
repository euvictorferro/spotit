import SwiftUI

struct NotificationsView: View {
    var body: some View {
        EmptyStateView(
            icon: "bell",
            message: "Em construção — aqui vão aparecer curtidas, comentários e novos seguidores."
        )
        .navigationTitle("Notificações")
    }
}

#Preview {
    NavigationStack { NotificationsView() }
}
