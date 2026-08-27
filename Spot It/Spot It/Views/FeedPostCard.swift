import SwiftUI

struct FeedPostCard: View {
    let post: FeedPost
    @State private var isLiked = false
    @State private var showDetails = false

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
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? .red : .primary)
            }
            Image(systemName: "bubble.right")
            Image(systemName: "paperplane")
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
}

/// Aberta ao tocar no ícone de info — mostra o que sumiu do card do feed
/// (modelo, ano, motor, raridade, fato interessante).
struct CarDetailSheet: View {
    let post: FeedPost
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Text(post.modelo).font(.title3).bold()
                        Spacer()
                        Text("\(post.raridade)/10")
                            .font(.subheadline).bold()
                            .foregroundStyle(Theme.rarityColor(post.raridade))
                    }
                    Text("Ano: \(post.ano)")
                    Text("Motor: \(post.motor)")
                    Text(post.valorEstimadoUsd, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text(post.fatoInteressante)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .rarityCard(post.raridade)
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Detalhes do carro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    FeedPostCard(post: FeedPost.sample[0])
        .padding()
}
