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
                .rarityPhotoBorder(post.raridade)
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
        .sheet(isPresented: $showDetails) {
            CarDetailSheet(post: post)
        }
        .sheet(isPresented: $showComments) {
            CommentsSheet(post: post, comments: $comments)
        }
    }

    private var header: some View {
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

    private var photo: some View {
        LinearGradient(colors: post.photoGradient, startPoint: .top, endPoint: .bottom)
    }

    private var valueChip: some View {
        Text(post.valorEstimadoUsd, format: .currency(code: "USD").precision(.fractionLength(0)))
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
                MessageCircleIcon.icon(size: 20)
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

/// Aberta ao tocar no ícone de info — mostra o que sumiu do card do feed
/// (modelo, ano, motor, raridade, fato interessante). Visual discreto de
/// propósito: sem glow, o card do feed já chama atenção o suficiente.
struct CarDetailSheet: View {
    let post: FeedPost
    @Environment(\.dismiss) private var dismiss

    private var rarityLabel: String {
        switch post.raridade {
        case ...3: return "Comum"
        case 4...6: return "Incomum"
        case 7...8: return "Raro"
        default: return "Lendário"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.modelo).font(.title3).bold()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.rarityColor(post.raridade))
                                .frame(width: 7, height: 7)
                            Text("\(rarityLabel) · \(post.raridade)/10")
                                .font(.footnote).fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        DetailRow(label: "Ano", value: "\(post.ano)")
                        DetailRow(label: "Motor", value: post.motor)
                        DetailRow(label: "Valor estimado", value: post.valorEstimadoUsd.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    }

                    Divider()

                    Text(post.fatoInteressante)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Detalhes do carro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    FeedPostCard(post: FeedPost.sample[0])
        .padding()
}
