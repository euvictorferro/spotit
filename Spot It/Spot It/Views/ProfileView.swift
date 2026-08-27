import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Em construção — foto de perfil, nome, bio, contagem de fotos/seguidores.")
                        .foregroundStyle(.secondary)
                }

                Section("Ranking") {
                    Text("Em construção — posição do usuário no ranking global de valor de wallet.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Perfil")
        }
    }
}

#Preview {
    ProfileView()
}
