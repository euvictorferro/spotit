import SwiftUI

struct EventsView: View {
    var body: some View {
        EmptyStateView(
            icon: "ticket",
            message: "Em construção — aqui vão aparecer os encontros de carro perto de você."
        )
        .navigationTitle("Eventos")
    }
}

#Preview {
    NavigationStack { EventsView() }
}
