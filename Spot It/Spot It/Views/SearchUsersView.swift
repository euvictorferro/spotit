import SwiftUI

/// Busca de usuários — quinta aba do menu, entre DM e Wallet. Reaproveita o
/// mesmo cabeçalho de busca do DM e navega pro mesmo UserProfileView usado
/// no resto do app.
struct SearchUsersView: View {
    @State private var search = ""
    @FocusState private var isSearchFocused: Bool
    // Reseta a navegação sempre que a aba fica inativa — sem isso, sair pro
    // perfil de alguém e trocar de aba deixava a busca "presa" lá.
    @State private var path = NavigationPath()

    // Sem backend de usuários/social ainda — sem resultados até ter busca real.
    private var results: [SearchableUser] { [] }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: Theme.Spacing.md) {
                searchField

                if results.isEmpty {
                    EmptyStateView(icon: "person.crop.circle.badge.questionmark", message: search.isEmpty ? "Busca de usuários ainda não disponível." : "Ninguém encontrado.")
                } else {
                    List(results) { user in
                        NavigationLink {
                            // ponytail: Busca ainda não tem backend real — sem userId real do usuário encontrado até então.
                            UserProfileView(username: user.username, avatarInitials: user.avatarInitials, avatarColors: user.avatarColors, userId: UUID())
                        } label: {
                            row(user)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Spot It").font(.headline)
                }
            }
        }
        .onDisappear {
            path = NavigationPath()
            isSearchFocused = false
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Buscar usuários", text: $search)
                .focused($isSearchFocused)
        }
        .padding(Theme.Spacing.sm)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func row(_ user: SearchableUser) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(LinearGradient(colors: user.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay(Text(user.avatarInitials).font(.caption).fontWeight(.bold).foregroundStyle(.white))

            Text(user.username).font(.subheadline).fontWeight(.medium)

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .foregroundStyle(.primary)
    }
}

#Preview {
    SearchUsersView()
}
