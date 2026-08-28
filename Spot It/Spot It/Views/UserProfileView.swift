import SwiftUI

private enum UserProfileTab: String, CaseIterable {
    case fotos = "Fotos"
    case summary = "Summary"
    case all = "All"
}

/// Perfil de outro usuário, aberto ao tocar no avatar/nome de um post do
/// feed. Mostra a grade de fotos que a pessoa postou no feed + a "coleção"
/// dela (mesmos Summary/All da Wallet, sem a aba Sets — não faz sentido
/// mostrar progresso de coleção de outra pessoa).
struct UserProfileView: View {
    let username: String
    let avatarInitials: String
    let avatarColors: [Color]

    @State private var tab: UserProfileTab = .fotos

    private var posts: [FeedPost] {
        FeedPost.sample.filter { $0.username == username }
    }

    private var items: [WalletItem] {
        posts.map { WalletItem(feedPost: $0) }
    }

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                header
                tabPicker

                switch tab {
                case .fotos:
                    photosGrid
                case .summary:
                    WalletSummaryView(items: items)
                case .all:
                    WalletAllView(items: items)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(LinearGradient(colors: avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 74, height: 74)
                .overlay(Text(avatarInitials).font(.title2).fontWeight(.bold).foregroundStyle(.white))

            Text(username).font(.headline)

            HStack(spacing: Theme.Spacing.lg) {
                statColumn(value: "\(posts.count)", label: "Fotos")
                // ponytail: seguidores/seguindo sem dado real ainda — placeholder até ter perfil no backend.
                statColumn(value: "—", label: "Seguidores")
                statColumn(value: "—", label: "Seguindo")
            }
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var tabPicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(UserProfileTab.allCases, id: \.self) { option in
                Button {
                    tab = option
                } label: {
                    Text(option.rawValue)
                        .font(.subheadline)
                        .fontWeight(tab == option ? .semibold : .regular)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(tab == option ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                        .foregroundStyle(tab == option ? .white : .primary)
                }
            }
        }
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
