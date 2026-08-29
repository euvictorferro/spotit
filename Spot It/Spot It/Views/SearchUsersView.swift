import SwiftUI

/// Busca de usuários — quinta aba do menu, entre DM e Wallet. Reaproveita o
/// mesmo cabeçalho de busca do DM e navega pro mesmo UserProfileView usado
/// no resto do app. Busca real contra `profiles` (tabela pública desde a
/// migration 0004) — sem sistema de social graph, só username/id/avatar.
struct SearchUsersView: View {
    @State private var search = ""
    @FocusState private var isSearchFocused: Bool
    // Reseta a navegação sempre que a aba fica inativa — sem isso, sair pro
    // perfil de alguém e trocar de aba deixava a busca "presa" lá.
    @State private var path = NavigationPath()

    @State private var results: [SearchableUser] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: Theme.Spacing.md) {
                searchField

                if let errorMessage {
                    EmptyStateView(icon: "exclamationmark.triangle", message: errorMessage)
                } else if search.isEmpty {
                    EmptyStateView(icon: "person.crop.circle.badge.questionmark", message: "Digite um username pra buscar.")
                } else if results.isEmpty && !isLoading {
                    EmptyStateView(icon: "person.crop.circle.badge.questionmark", message: "Ninguém encontrado.")
                } else {
                    List(results) { user in
                        NavigationLink {
                            UserProfileView(username: user.username, avatarInitials: user.avatarInitials, avatarColors: user.avatarColors, userId: user.id)
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
        // .task(id:) cancela a busca anterior sozinho quando `search` muda de
        // novo antes dela terminar — evita resposta velha sobrescrever uma
        // busca mais recente (condição de corrida ao digitar rápido).
        .task(id: search) {
            await search(query: search)
        }
    }

    private func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }
        isLoading = true
        do {
            results = try await SupabaseService.searchProfiles(username: trimmed)
            errorMessage = nil
        } catch {
            errorMessage = "Não deu pra buscar agora. Tenta de novo."
        }
        isLoading = false
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
