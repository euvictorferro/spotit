import SwiftUI

struct FeedPostCard: View {
    let post: FeedPost
    @State private var isLiked = false
    @State private var likeCount = Int.random(in: 40...900)
    @State private var comments: [Comment]
    @State private var showDetails = false
    @State private var showComments = false

    init(post: FeedPost) {
        self.post = post
        self._comments = State(initialValue: Comment.sampleFor(post))
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

            Text("Curtido por **\(post.likedByUsername)** e outros")
                .font(.footnote)

            (Text(post.username).fontWeight(.semibold) + Text(" " + post.caption))
                .font(.footnote)
        }
        .fullScreenCover(isPresented: $showDetails) {
            CarDetailPageView(item: WalletItem(feedPost: post))
        }
        .sheet(isPresented: $showComments) {
            CommentsSheet(post: post, comments: $comments)
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            NavigationLink {
                UserProfileView(username: post.username, avatarInitials: post.avatarInitials, avatarColors: post.avatarColors)
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(LinearGradient(colors: post.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 30, height: 30)
                        .overlay(Text(post.avatarInitials).font(.caption2).fontWeight(.bold).foregroundStyle(.white))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.username).font(.subheadline).fontWeight(.semibold)
                        Text("\(post.location) · \(post.timeAgo)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if !post.isFollowing {
                FollowButton()
            }
        }
    }

    private var photo: some View {
        LinearGradient(colors: post.photoGradient, startPoint: .top, endPoint: .bottom)
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
                isLiked.toggle()
                likeCount += isLiked ? 1 : -1
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? .red : .primary)
            }

            Button {
                showComments = true
            } label: {
                HStack(spacing: 4) {
                    MessageCircleIcon.icon(size: 20)
                    if !comments.isEmpty {
                        Text(comments.count.formattedCount)
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

    private var shareText: String {
        "Olha esse carro que eu achei no Spot It! 🏎️"
    }
}

/// Botão "Seguir" → "Seguindo" com estado local — só aparece nos posts de
/// quem ainda não segue (post.isFollowing == false).
private struct FollowButton: View {
    @State private var isFollowing = false

    var body: some View {
        Button {
            isFollowing.toggle()
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
    }
}

#Preview {
    NavigationStack {
        FeedPostCard(post: FeedPost.sample[0])
            .padding()
    }
}
