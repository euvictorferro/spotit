import SwiftUI

struct NotificationsView: View {
    var body: some View {
        List {
            Text("Em construção — aqui vão aparecer curtidas, comentários e novos seguidores.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Notificações")
    }
}

#Preview {
    NavigationStack { NotificationsView() }
}
