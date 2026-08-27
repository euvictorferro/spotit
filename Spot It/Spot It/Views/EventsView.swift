import SwiftUI

struct EventsView: View {
    var body: some View {
        List {
            Text("Em construção — aqui vão aparecer os encontros de carro perto de você.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Eventos")
    }
}

#Preview {
    NavigationStack { EventsView() }
}
