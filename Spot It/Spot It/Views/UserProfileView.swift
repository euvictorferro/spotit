import SwiftUI

private enum UserProfileTab {
    case fotos, summary, all

    var icon: String {
        switch self {
        case .fotos: return "square.grid.2x2"
        case .summary: return "chart.bar"
        case .all: return "list.bullet"
        }
    }
}

/// Perfil de outro usuário, aberto ao tocar no avatar/nome de um post do
/// feed. Mesmo padrão visual do nosso próprio perfil (ProfileView), com
/// Seguir no lugar de Editar e Fotos/Summary/All no lugar de Fotos/Ranking
/// — mostra a grade de fotos que a pessoa postou no feed + a "coleção" dela
/// (mesmos Summary/All da Wallet, sem a aba Sets — não faz sentido mostrar
/// progresso de coleção de outra pessoa).
struct UserProfileView: View {
    let username: String
    let avatarInitials: String
    let avatarColors: [Color]

    @State private var tab: UserProfileTab = .fotos
    @State private var isFollowing = false
    @State private var conversation: DMConversation

    init(username: String, avatarInitials: String, avatarColors: [Color]) {
        self.username = username
        self.avatarInitials = avatarInitials
        self.avatarColors = avatarColors
        _conversation = State(initialValue: DMConversation(
            username: username, avatarColors: avatarColors, avatarInitials: avatarInitials,
            lastMessage: "", timeAgo: "", messages: []
        ))
    }

    // Sem backend social ainda — perfil de outros usuários fica vazio.
    private var posts: [FeedPost] { [] }

    private var items: [WalletItem] {
        posts.map { WalletItem(feedPost: $0) }
    }

    /// Posição dessa pessoa no ranking global — vira busca real quando o
    /// ranking for calculado a partir de dados do backend.
    private var rankingPosition: Int? { nil }

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, Theme.Spacing.md)

                tabBar
                    .padding(.top, Theme.Spacing.md)

                switch tab {
                case .fotos:
                    photosGrid
                case .summary:
                    VStack(spacing: Theme.Spacing.lg) {
                        if let rankingPosition {
                            rankingPositionSection(rankingPosition)
                        }
                        WalletSummaryView(items: items)
                    }
                    .padding(Theme.Spacing.md)
                case .all:
                    WalletAllView(items: .constant(items))
                        .padding(Theme.Spacing.md)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("@\(username)").font(.headline)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.lg) {
                Circle()
                    .fill(LinearGradient(colors: avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 74, height: 74)
                    .overlay(Text(avatarInitials).font(.title2).fontWeight(.bold).foregroundStyle(.white))

                HStack(spacing: Theme.Spacing.lg) {
                    statColumn(value: "\(posts.count)", label: "posts")
                    // ponytail: seguidores/seguindo sem dado real ainda — placeholder até ter perfil no backend.
                    statColumn(value: "—", label: "seguidores")
                    statColumn(value: "—", label: "seguindo")
                }
            }

            Text(username).font(.subheadline).fontWeight(.semibold)

            HStack(spacing: Theme.Spacing.sm) {
                Button {
                    isFollowing.toggle()
                } label: {
                    Text(isFollowing ? "Seguindo" : "Seguir")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isFollowing ? Color(.secondarySystemBackground) : Color.accentColor)
                .foregroundStyle(isFollowing ? Color.primary : Color.white)

                NavigationLink(destination: ChatThreadView(conversation: $conversation)) {
                    Text("Mensagem")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, Theme.Spacing.xs)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.fotos)
            tabButton(.summary)
            tabButton(.all)
        }
        .overlay(Divider(), alignment: .top)
    }

    private func tabButton(_ option: UserProfileTab) -> some View {
        Button {
            tab = option
        } label: {
            Image(systemName: option.icon)
                .font(.system(size: 20))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .foregroundStyle(tab == option ? .primary : .secondary)
                .overlay(alignment: .bottom) {
                    if tab == option {
                        Rectangle().fill(Color.primary).frame(height: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func rankingPositionSection(_ position: Int) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Label("Ranking", systemImage: "trophy")
                .font(.headline)
            Spacer()
            Text("#\(position) no ranking global")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var photosGrid: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(posts) { post in
                LinearGradient(colors: post.photoGradient, startPoint: .top, endPoint: .bottom)
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(username: "rk.spotter", avatarInitials: "RK", avatarColors: [.purple, .indigo])
    }
}
