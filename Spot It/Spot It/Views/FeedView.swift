import SwiftUI

struct FeedView: View {
    // Reseta a navegação sempre que a aba fica inativa — sem isso, sair
    // pro perfil de alguém e trocar de aba deixava o Feed "preso" lá.
    @State private var path = NavigationPath()

    @State private var posts: [DBPost] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if posts.isEmpty {
                    EmptyStateView(icon: "photo.on.rectangle", message: "Nenhum post ainda. Siga outros spotters pra ver o feed.")
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.lg) {
                            ForEach(posts) { post in
                                FeedPostCard(post: post)
                            }
                        }
                        .padding(Theme.Spacing.md)
                    }
                }
            }
            .background(AppGradientBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Spot It").font(.headline)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink(destination: MapView(scope: .feed)) {
                        Image(systemName: "globe")
                    }
                    NavigationLink(destination: EventsView()) {
                        Image(systemName: "ticket")
                    }
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .task { await load() }
            .refreshable { await load() }
        }
        .preferredColorScheme(.dark)
        .onDisappear { path = NavigationPath() }
    }

    private func load() async {
        posts = (try? await SupabaseService.fetchFeedPosts()) ?? []
    }
}

#Preview {
    FeedView()
}
