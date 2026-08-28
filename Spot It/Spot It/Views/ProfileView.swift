import SwiftUI

private enum ProfileTab: String, CaseIterable {
    case fotos = "Fotos"
    case summary = "Summary"
    case all = "All"
    case ranking = "Ranking"
}

struct ProfileView: View {
    @State private var items: [WalletItem] = []
    @State private var isLoading = true
    @State private var tab: ProfileTab = .fotos
    @State private var showSettings = false

    private let ranking = RankingEntry.sample.sorted { $0.walletValueUsd > $1.walletValueUsd }

    private var myPosition: Int {
        (ranking.firstIndex { $0.isMe } ?? 0) + 1
    }

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    header
                    tabPicker

                    switch tab {
                    case .fotos:
                        photosGrid
                    case .summary:
                        WalletSummaryView(items: items)
                    case .all:
                        WalletAllView(items: items)
                    case .ranking:
                        rankingSection
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Spot It").font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .overlay {
                if isLoading && items.isEmpty {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
            }
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(LinearGradient(colors: [.red, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 74, height: 74)
                .overlay(Text("VF").font(.title2).fontWeight(.bold).foregroundStyle(.white))

            Text("victorferro").font(.headline)

            HStack(spacing: Theme.Spacing.lg) {
                statColumn(value: "\(items.count)", label: "Fotos")
                statColumn(value: "340", label: "Seguidores")
                statColumn(value: "180", label: "Seguindo")
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(ProfileTab.allCases, id: \.self) { option in
                    Button {
                        tab = option
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline)
                            .fontWeight(tab == option ? .semibold : .regular)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(tab == option ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                            .foregroundStyle(tab == option ? .white : .primary)
                    }
                }
            }
        }
    }

    private var photosGrid: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(items) { item in
                LinearGradient(
                    colors: [Theme.rarityColor(item.raridade).opacity(0.6), Theme.rarityColor(item.raridade).opacity(0.15)],
                    startPoint: .top, endPoint: .bottom
                )
                .aspectRatio(1, contentMode: .fill)
                .overlay(Image(systemName: "car.side.fill").foregroundStyle(Theme.rarityColor(item.raridade)))
                .clipped()
            }
        }
    }

    private var rankingSection: some View {
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

    private func load() async {
        isLoading = true
        let fetched = (try? await SupabaseService.fetchWalletItems()) ?? []
        items = fetched.isEmpty ? WalletItem.sample : fetched
        isLoading = false
    }
}

/// Placeholder de configurações — sem lógica ainda, só o esqueleto visual
/// até termos conta/auth de verdade pra editar perfil ou deslogar.
private struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Label("Editar perfil", systemImage: "person.crop.circle")
                Label("Notificações", systemImage: "bell")
                Label("Privacidade", systemImage: "lock")
                Label("Sair", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(.red)
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
