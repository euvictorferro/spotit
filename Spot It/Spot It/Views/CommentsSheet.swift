import SwiftUI

struct CommentsSheet: View {
    let post: FeedPost
    @Binding var comments: [Comment]
    @State private var newComment = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach($comments) { $comment in
                        row($comment)
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
    }

    private func row(_ comment: Binding<Comment>) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Circle()
                .fill(LinearGradient(colors: comment.wrappedValue.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 34)
                .overlay(Text(comment.wrappedValue.avatarInitials).font(.caption2).fontWeight(.bold).foregroundStyle(.white))

            VStack(alignment: .leading, spacing: 4) {
                (Text(comment.wrappedValue.username).fontWeight(.semibold) + Text("  " + comment.wrappedValue.text))
                    .font(.subheadline)

                HStack(spacing: Theme.Spacing.md) {
                    Text(comment.wrappedValue.timeAgo)
                    Button("Responder") {
                        reply(to: comment.wrappedValue.username)
                    }
                    .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: Theme.Spacing.sm)

            VStack(spacing: 3) {
                Button {
                    comment.wrappedValue.isLiked.toggle()
                    comment.wrappedValue.likeCount += comment.wrappedValue.isLiked ? 1 : -1
                } label: {
                    Image(systemName: comment.wrappedValue.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(comment.wrappedValue.isLiked ? .red : .secondary)
                        .font(.footnote)
                }
                .buttonStyle(.plain)

                Text("\(comment.wrappedValue.likeCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func reply(to username: String) {
        newComment = "@\(username) "
        isInputFocused = true
    }

    private func send() {
        let text = newComment.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        comments.append(Comment(username: "victorferro", text: text, timeAgo: "agora", avatarColors: [.red, .black]))
        newComment = ""
    }
}

#Preview {
    CommentsSheet(post: FeedPost.sample[0], comments: .constant(Comment.sampleFor(FeedPost.sample[0])))
}
