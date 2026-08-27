import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.tertiary)
                        Text("Em construção — foto de perfil, nome, bio, contagem de fotos/seguidores.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.lg)

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("Ranking", systemImage: "trophy")
                            .font(.headline)
                        Text("Em construção — posição do usuário no ranking global de valor de wallet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Perfil")
        }
    }
}

#Preview {
    ProfileView()
}
