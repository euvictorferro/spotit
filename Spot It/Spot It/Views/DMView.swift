import SwiftUI

struct DMView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                icon: "message",
                message: "Em construção — aqui vão aparecer suas conversas com outros usuários."
            )
            .navigationTitle("Mensagens")
        }
    }
}

#Preview {
    DMView()
}
