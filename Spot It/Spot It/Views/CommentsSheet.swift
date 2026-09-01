import Auth
import SwiftUI

struct CommentsSheet: View {
    let post: DBPost
    @EnvironmentObject private var authService: AuthService
    @State private var comments: [DBComment] = []
    @State private var newComment = ""
    @State private var errorMessage: String?
    @State private var loadFailed = false
    @FocusState private var isInputFocused: Bool

    private var myAvatar: SearchableUser {
        SearchableUser(id: authService.session?.user.id ?? UUID(), username: authService.profile?.username ?? "eu")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(comments) { comment in
                        row(comment)
                            .listRowInsets(EdgeInsets(top: 10, leading: Theme.Spacing.md, bottom: 10, trailing: Theme.Spacing.md))
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable { await load() }

                if loadFailed {
                    Text("Não deu pra carregar os comentários. Puxe a lista pra tentar de novo.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(Theme.Spacing.md)
                }

                Divider()

                HStack(spacing: Theme.Spacing.sm) {
                    AvatarView(user: myAvatar, url: authService.profile?.avatarUrl, size: 28)

                    TextField("Adicione um comentário para \(post.username)...", text: $newComment)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)

                    Button("Enviar") {
                        send()
                    }
                    .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
                .padding(Theme.Spacing.md)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.sm)
                }
            }
            .navigationTitle("Comentários")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .task { await load() }
    }

    private func row(_ comment: DBComment) -> some View {
        let avatar = SearchableUser(id: comment.userId, username: comment.username)
        return HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            AvatarView(user: avatar, url: comment.avatarUrl, size: 34)

            VStack(alignment: .leading, spacing: 4) {
                (Text(comment.username).fontWeight(.semibold) + Text("  " + comment.text))
                    .font(.subheadline)

                HStack(spacing: Theme.Spacing.md) {
                    Text(comment.createdAt.formatted(.relative(presentation: .named)))
                    Button("Responder") {
                        reply(to: comment.username)
                    }
                    .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: Theme.Spacing.sm)
        }
    }

    private func reply(to username: String) {
        newComment = "@\(username) "
        isInputFocused = true
    }

    private func load() async {
        loadFailed = false
        do {
            comments = try await SupabaseService.fetchComments(postId: post.id)
        } catch {
            loadFailed = true
        }
    }

    private func send() {
        let text = newComment.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        errorMessage = nil
        Task {
            do {
                try await SupabaseService.addComment(postId: post.id, text: text)
                newComment = ""
                await load()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    CommentsSheet(post: DBPost(id: UUID(), userId: UUID(), username: "rk.spotter", avatarUrl: nil, modelo: "Porsche 911 GT3 RS", raridade: 8, valorEstimadoUsd: 223_000, fotoUrl: "", photos: [""], location: nil, caption: nil, createdAt: Date(), likeCount: 0, commentCount: 0, likedByMe: false))
}
