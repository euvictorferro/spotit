import SwiftUI
import Supabase

struct FeedPostCard: View {
    let post: DBPost
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var showDetails = false
    @State private var showComments = false

    init(post: DBPost) {
        self.post = post
        self._isLiked = State(initialValue: post.likedByMe)
        self._likeCount = State(initialValue: post.likeCount)
    }

    private var avatar: SearchableUser {
        SearchableUser(id: post.userId, username: post.username)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            header

            photo
                .aspectRatio(4 / 5, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(alignment: .topTrailing) {
                    valueChip
                }

            actions
                .padding(.top, Theme.Spacing.xs)

            if likeCount > 0 {
                Text("\(likeCount) curtidas")
                    .font(.footnote)
            }

            captionText
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
            NavigationLink {
                UserProfileView(username: post.username, avatarInitials: avatar.avatarInitials, avatarColors: avatar.avatarColors, userId: post.userId)
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(LinearGradient(colors: avatar.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 30, height: 30)
                        .overlay(Text(avatar.avatarInitials).font(.caption2).fontWeight(.bold).foregroundStyle(.white))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.username).font(.subheadline).fontWeight(.semibold)
                        Text(post.createdAt.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if post.userId != SupabaseService.client.auth.currentSession?.user.id {
                FollowButton(userId: post.userId)
            }
        }
    }

    private var photo: some View {
        AsyncImage(url: URL(string: post.fotoUrl)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                LinearGradient(
                    colors: [Theme.rarityColor(post.raridade).opacity(0.6), Theme.rarityColor(post.raridade).opacity(0.15)],
                    startPoint: .top, endPoint: .bottom
                )
                .overlay(Image(systemName: "car.side.fill").foregroundStyle(Theme.rarityColor(post.raridade)))
            }
        }
    }

    private var valueChip: some View {
        Text(post.valorEstimadoUsd.asDollars)
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

            Button {
                showDetails = true
            } label: {
                Image(systemName: "info.circle")
            }
        }
        .font(.system(size: 20))
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
    }

    private func toggleLike() {
        let wasLiked = isLiked
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1
        Task {
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
        FeedPostCard(post: DBPost(id: UUID(), userId: UUID(), username: "rk.spotter", avatarUrl: nil, modelo: "Porsche 911 GT3 RS", raridade: 8, valorEstimadoUsd: 223_000, fotoUrl: "", caption: "track day pack completo", createdAt: Date(), likeCount: 42, commentCount: 3, likedByMe: false))
            .padding()
    }
}
