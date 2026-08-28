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

    private var results: [SearchableUser] {
        guard !search.isEmpty else { return SearchableUser.sample }
        return SearchableUser.sample.filter { $0.username.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: Theme.Spacing.md) {
                searchField

                List(results) { user in
                    NavigationLink {
                        UserProfileView(username: user.username, avatarInitials: user.avatarInitials, avatarColors: user.avatarColors)
                    } label: {
                        row(user)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
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
