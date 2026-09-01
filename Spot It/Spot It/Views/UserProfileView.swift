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
    let userId: UUID?

    @State private var tab: UserProfileTab = .fotos
    @State private var isFollowing = false
    @State private var isTogglingFollow = false
    @State private var followersCount = 0
    @State private var followingCount = 0
    @State private var openConversationId: UUID?
    @State private var isStartingConversation = false
    @State private var errorMessage: String?
    @State private var isBlocked = false
    @State private var isTogglingBlock = false
    @State private var showReport = false
    @State private var showBlockConfirm = false
    @State private var avatarUrl: String?

    init(username: String, avatarInitials: String, avatarColors: [Color], userId: UUID?) {
        self.username = username
        self.avatarInitials = avatarInitials
        self.avatarColors = avatarColors
        self.userId = userId
    }

    @State private var posts: [DBPost] = []

    private var items: [WalletItem] {
        posts.map { WalletItem(dbPost: $0) }
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
            if let userId {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Denunciar Perfil", systemImage: "flag") { showReport = true }
                        Button(
                            isBlocked ? "Desbloquear" : "Bloquear",
                            systemImage: "hand.raised",
                            role: isBlocked ? nil : .destructive
                        ) {
                            if isBlocked {
                                Task { await toggleBlock() }
                            } else {
                                showBlockConfirm = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showReport) {
            ReportSheet { reason in
                try await SupabaseService.reportUser(userId: userId, postId: nil, reason: reason)
            }
        }
        .confirmationDialog("Bloquear @\(username)?", isPresented: $showBlockConfirm, titleVisibility: .visible) {
            Button("Bloquear", role: .destructive) { Task { await toggleBlock() } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Vocês não vão mais ver posts, comentários nem mensagens um do outro.")
        }
        .task {
            await loadFollowState()
            await loadPosts()
            await loadBlockState()
            await loadAvatar()
        }
    }

    private func loadAvatar() async {
        guard let userId else { return }
        avatarUrl = try? await SupabaseService.fetchProfile(userId: userId).avatarUrl
    }

    private func loadBlockState() async {
        guard let userId else { return }
        isBlocked = (try? await SupabaseService.isBlocked(userId: userId)) ?? false
    }

    private func toggleBlock() async {
        guard let userId, !isTogglingBlock else { return }
        isTogglingBlock = true
        defer { isTogglingBlock = false }
        do {
            if isBlocked {
                try await SupabaseService.unblockUser(userId: userId)
                isBlocked = false
            } else {
                try await SupabaseService.blockUser(userId: userId)
                isBlocked = true
                isFollowing = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadFollowState() async {
        // ponytail: userId nil = Feed/Notificações ainda sem backend real (mock) — sem rede, sem contagens.
        guard let userId else { return }
        do {
            async let following = SupabaseService.isFollowing(userId: userId)
            async let counts = SupabaseService.followCounts(userId: userId)
            isFollowing = try await following
            let (followers, followingC) = try await counts
            followersCount = followers
            followingCount = followingC
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPosts() async {
        guard let userId else { return }
        posts = (try? await SupabaseService.fetchPosts(userId: userId)) ?? []
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.lg) {
                AvatarView(url: avatarUrl, initials: avatarInitials, colors: avatarColors, size: 74)

                HStack(spacing: Theme.Spacing.lg) {
                    statColumn(value: "\(posts.count)", label: "posts")
                    statColumn(value: userId != nil ? "\(followersCount)" : "—", label: "seguidores")
                    statColumn(value: userId != nil ? "\(followingCount)" : "—", label: "seguindo")
                }
            }

            Text(username).font(.subheadline).fontWeight(.semibold)

            if userId != nil {
                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        Task { await toggleFollow() }
                    } label: {
                        Text(isFollowing ? "Seguindo" : "Seguir")
                            .font(.subheadline).fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isFollowing ? Color(.secondarySystemBackground) : Color.accentColor)
                    .foregroundStyle(isFollowing ? Color.primary : Color.white)
                    .disabled(isTogglingFollow)

                    Button {
                        Task { await startConversation() }
                    } label: {
                        Text("Mensagem")
                            .font(.subheadline).fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isStartingConversation)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(.top, Theme.Spacing.xs)
        .navigationDestination(item: $openConversationId) { conversationId in
            if let userId {
                ChatThreadView(conversationId: conversationId, otherUserId: userId, otherUsername: username, otherAvatarUrl: nil)
            }
        }
    }

    private func toggleFollow() async {
        guard let userId else { return }
        errorMessage = nil
        isTogglingFollow = true
        defer { isTogglingFollow = false }
        do {
            if isFollowing {
                try await SupabaseService.unfollow(userId: userId)
                isFollowing = false
                followersCount = max(0, followersCount - 1)
            } else {
                try await SupabaseService.follow(userId: userId)
                isFollowing = true
                followersCount += 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startConversation() async {
        guard let userId else { return }
        errorMessage = nil
        isStartingConversation = true
        defer { isStartingConversation = false }
        do {
            openConversationId = try await SupabaseService.startOrFetchConversation(withUserId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
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
                NavigationLink {
                    if post.isCarPost {
                        CarDetailPageView(item: WalletItem(dbPost: post))
                    } else {
                        PostDetailView(post: post)
                    }
                } label: {
                    WalletPhotoThumb(fotoUrl: post.fotoUrl, raridade: post.raridade ?? 1)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3 / 4, contentMode: .fill)
                        .clipped()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(username: "rk.spotter", avatarInitials: "RK", avatarColors: [.purple, .indigo], userId: nil)
    }
}
