import SwiftUI
import Supabase

struct FeedPostCard: View {
    let post: DBPost
    @EnvironmentObject private var tabSelection: TabSelection
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var showDetails = false
    @State private var showComments = false
    @State private var showReport = false
    @State private var showBlockConfirm = false
    @State private var isBlocking = false
    @State private var isTogglingLike = false
    var onBlocked: (() -> Void)?

    init(post: DBPost, onBlocked: (() -> Void)? = nil) {
        self.post = post
        self.onBlocked = onBlocked
        self._isLiked = State(initialValue: post.likedByMe)
        self._likeCount = State(initialValue: post.likeCount)
    }

    private var avatar: SearchableUser {
        SearchableUser(id: post.userId, username: post.username)
    }

    private var isMine: Bool {
        post.userId == SupabaseService.client.auth.currentSession?.user.id
    }

    private var headerContent: some View {
        HStack(spacing: Theme.Spacing.sm) {
            AvatarView(user: avatar, url: post.avatarUrl, size: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(post.username).font(.subheadline).fontWeight(.semibold)
                Text(post.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            header

            photo
                .aspectRatio(4 / 5, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(alignment: .topTrailing) {
                    if post.isCarPost { valueChip }
                }

            actions
                .padding(.top, Theme.Spacing.xs)

            if likeCount > 0 {
                Text(likeCount == 1 ? "1 curtida" : "\(likeCount) curtidas")
                    .font(.footnote)
            }

            captionText

            if let location = post.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(location)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .fullScreenCover(isPresented: $showDetails) {
            CarDetailPageView(item: WalletItem(dbPost: post))
        }
        .sheet(isPresented: $showComments) {
            CommentsSheet(post: post)
        }
    }

    @ViewBuilder
    private var captionText: some View {
        if let caption = post.caption, !caption.isEmpty {
            (Text(post.username).fontWeight(.semibold) + Text(" " + caption))
                .font(.footnote)
        } else {
            Text(post.username).fontWeight(.semibold)
                .font(.footnote)
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Group {
                if isMine {
                    // Seu próprio post: vai pra aba Perfil de verdade (editável),
                    // não pro perfil "de visualização" (Seguir/Bloquear) que só
                    // faz sentido pra outra pessoa.
                    Button {
                        tabSelection.selected = .profile
                    } label: {
                        headerContent
                    }
                } else {
                    NavigationLink {
                        UserProfileView(username: post.username, avatarInitials: avatar.avatarInitials, avatarColors: avatar.avatarColors, userId: post.userId)
                    } label: {
                        headerContent
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if !isMine {
                FollowButton(userId: post.userId)

                Menu {
                    Button("Denunciar Post", systemImage: "flag") { showReport = true }
                    Button("Bloquear @\(post.username)", systemImage: "hand.raised", role: .destructive) { showBlockConfirm = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(.leading, Theme.Spacing.xs)
                }
            }
        }
        .sheet(isPresented: $showReport) {
            ReportSheet { reason in
                try await SupabaseService.reportUser(userId: post.userId, postId: post.id, reason: reason)
            }
        }
        .confirmationDialog("Bloquear @\(post.username)?", isPresented: $showBlockConfirm, titleVisibility: .visible) {
            Button("Bloquear", role: .destructive) { Task { await block() } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Vocês não vão mais ver posts, comentários nem mensagens um do outro.")
        }
        .disabled(isBlocking)
    }

    private func block() async {
        isBlocking = true
        defer { isBlocking = false }
        if (try? await SupabaseService.blockUser(userId: post.userId)) != nil {
            onBlocked?()
        }
    }

    /// Carrossel quando tem mais de 1 foto (post casual do feed) — post de
    /// carro sempre tem 1 foto só, então cai direto na imagem única.
    private var photo: some View {
        Group {
            if post.photos.count > 1 {
                TabView {
                    ForEach(post.photos, id: \.self) { url in
                        photoImage(url)
                    }
                }
                .tabViewStyle(.page)
            } else {
                photoImage(post.fotoUrl)
            }
        }
    }

    private func photoImage(_ url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                LinearGradient(
                    colors: [placeholderColor.opacity(0.6), placeholderColor.opacity(0.15)],
                    startPoint: .top, endPoint: .bottom
                )
                .overlay(Image(systemName: "car.side.fill").foregroundStyle(placeholderColor))
            }
        }
    }

    private var placeholderColor: Color {
        post.raridade.map(Theme.rarityColor) ?? .gray
    }

    private var valueChip: some View {
        Text((post.valorEstimadoUsd ?? 0).asDollars)
            .font(.system(.footnote, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 5)
            .background(.black.opacity(0.45), in: Capsule())
            .padding(Theme.Spacing.sm)
    }

    private var actions: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                toggleLike()
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? .red : .primary)
            }
            .disabled(isTogglingLike)

            Button {
                showComments = true
            } label: {
                HStack(spacing: 4) {
                    MessageCircleIcon.icon(size: 20)
                    if post.commentCount > 0 {
                        Text(post.commentCount.formattedCount)
                            .font(.subheadline)
                    }
                }
            }

            ShareLink(item: shareText) {
                Image(systemName: "paperplane")
            }

            Spacer()

            if post.isCarPost {
                Button {
                    showDetails = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .font(.system(size: 20))
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
    }

    private func toggleLike() {
        guard !isTogglingLike else { return }
        isTogglingLike = true
        let wasLiked = isLiked
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1
        Task {
            defer { isTogglingLike = false }
            if let liked = try? await SupabaseService.toggleLike(postId: post.id) {
                isLiked = liked
            } else {
                // reverte se a chamada falhar
                isLiked = wasLiked
                likeCount += wasLiked ? 1 : -1
            }
        }
    }

    private var shareText: String {
        "Olha esse carro que eu achei no Spot It! 🏎️"
    }
}

/// Botão "Seguir" → "Seguindo" com estado real via SupabaseService — mesmo
/// padrão de UserProfileView.toggleFollow().
private struct FollowButton: View {
    let userId: UUID
    @State private var isFollowing = false
    @State private var isToggling = false

    var body: some View {
        Button {
            Task { await toggle() }
        } label: {
            Text(isFollowing ? "Seguindo" : "Seguir")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 6)
                .background(
                    isFollowing ? Color(.secondarySystemBackground) : Color.accentColor,
                    in: Capsule()
                )
                .foregroundStyle(isFollowing ? Color.primary : Color.white)
        }
        .buttonStyle(.plain)
        .disabled(isToggling)
        .task { isFollowing = (try? await SupabaseService.isFollowing(userId: userId)) ?? false }
    }

    private func toggle() async {
        isToggling = true
        defer { isToggling = false }
        do {
            if isFollowing {
                try await SupabaseService.unfollow(userId: userId)
                isFollowing = false
            } else {
                try await SupabaseService.follow(userId: userId)
                isFollowing = true
            }
        } catch {
            // ponytail: falha silenciosa — botão volta pro estado anterior, sem toast por ora.
        }
    }
}

#Preview {
    NavigationStack {
        FeedPostCard(post: DBPost(id: UUID(), userId: UUID(), username: "rk.spotter", avatarUrl: nil, modelo: "Porsche 911 GT3 RS", raridade: 8, valorEstimadoUsd: 223_000, fotoUrl: "", photos: [""], location: nil, caption: "track day pack completo", createdAt: Date(), likeCount: 42, commentCount: 3, likedByMe: false))
            .environmentObject(TabSelection())
            .padding()
    }
}
