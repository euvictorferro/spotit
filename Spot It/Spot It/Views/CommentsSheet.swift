import SwiftUI

struct CommentsSheet: View {
    let post: FeedPost
    @Binding var comments: [Comment]
    @State private var newComment = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List(comments) { comment in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comment.username).font(.subheadline).fontWeight(.semibold)
                        Text(comment.text).font(.subheadline)
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)

                Divider()

                HStack(spacing: Theme.Spacing.sm) {
                    TextField("Adicionar comentário...", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                    Button("Enviar") {
                        send()
                    }
                    .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Comentários")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func send() {
        let text = newComment.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        comments.append(Comment(username: "victorferro", text: text))
        newComment = ""
    }
}

#Preview {
    CommentsSheet(post: FeedPost.sample[0], comments: .constant(Comment.sampleFor(FeedPost.sample[0])))
}
