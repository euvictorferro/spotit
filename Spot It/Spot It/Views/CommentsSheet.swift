import SwiftUI

struct CommentsSheet: View {
    let post: DBPost
    @State private var comments: [DBComment] = []
    @State private var newComment = ""
    @FocusState private var isInputFocused: Bool

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

                Divider()

                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(LinearGradient(colors: [.red, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                        .overlay(Text("VF").font(.system(size: 10)).fontWeight(.bold).foregroundStyle(.white))

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
            Circle()
                .fill(LinearGradient(colors: avatar.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 34)
                .overlay(Text(avatar.avatarInitials).font(.caption2).fontWeight(.bold).foregroundStyle(.white))

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
        comments = (try? await SupabaseService.fetchComments(postId: post.id)) ?? []
    }

    private func send() {
        let text = newComment.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        newComment = ""
        Task {
            try? await SupabaseService.addComment(postId: post.id, text: text)
            await load()
        }
    }
}

#Preview {
    CommentsSheet(post: DBPost(id: UUID(), userId: UUID(), username: "rk.spotter", avatarUrl: nil, modelo: "Porsche 911 GT3 RS", raridade: 8, valorEstimadoUsd: 223_000, fotoUrl: "", caption: nil, createdAt: Date(), likeCount: 0, commentCount: 0, likedByMe: false))
}
