import SwiftUI

struct FeedView: View {
    // Reseta a navegação sempre que a aba fica inativa — sem isso, sair
    // pro perfil de alguém e trocar de aba deixava o Feed "preso" lá.
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    ForEach(FeedPost.sample) { post in
                        FeedPostCard(post: post)
                    }
                }
                .padding(Theme.Spacing.md)
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
        }
        .preferredColorScheme(.dark)
        .onDisappear { path = NavigationPath() }
    }
}

#Preview {
    FeedView()
}
