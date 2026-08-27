import SwiftUI

struct DMView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Em construção — aqui vão aparecer suas conversas com outros usuários.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Mensagens")
        }
    }
}

#Preview {
    DMView()
}
