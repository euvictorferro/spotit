import SwiftUI

struct ProfileView: View {
    private let ranking = RankingEntry.sample.sorted { $0.walletValueUsd > $1.walletValueUsd }

    private var myPosition: Int {
        (ranking.firstIndex { $0.isMe } ?? 0) + 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    VStack(spacing: Theme.Spacing.sm) {
                        Circle()
                            .fill(LinearGradient(colors: [.red, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 74, height: 74)
                            .overlay(Text("VF").font(.title2).fontWeight(.bold).foregroundStyle(.white))

                        Text("victorferro").font(.headline)

                        HStack(spacing: Theme.Spacing.lg) {
                            statColumn(value: "12", label: "Fotos")
                            statColumn(value: "340", label: "Seguidores")
                            statColumn(value: "180", label: "Seguindo")
                        }
                    }
                    .padding(.top, Theme.Spacing.lg)

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Label("Ranking", systemImage: "trophy")
                                .font(.headline)
                            Spacer()
                            Text("Você: #\(myPosition)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(Array(ranking.enumerated()), id: \.element.id) { index, entry in
                            HStack(spacing: Theme.Spacing.sm) {
                                Text("#\(index + 1)")
                                    .font(.subheadline).fontWeight(.bold)
                                    .foregroundStyle(index == 0 ? .yellow : .secondary)
                                    .frame(width: 28, alignment: .leading)

                                Circle()
                                    .fill(LinearGradient(colors: entry.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 34, height: 34)
                                    .overlay(Text(entry.avatarInitials).font(.caption2).fontWeight(.bold).foregroundStyle(.white))

                                Text(entry.username)
                                    .font(.subheadline)
                                    .fontWeight(entry.isMe ? .bold : .regular)

                                Spacer()

                                Text(entry.walletValueUsd.asDollars)
                                    .font(.system(.footnote, design: .rounded, weight: .bold))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, entry.isMe ? Theme.Spacing.sm : 0)
                            .background {
                                if entry.isMe {
                                    RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.12))
                                }
                            }
                        }
                    }
                    .card()
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Perfil")
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ProfileView()
}
