import SwiftUI

struct FeedView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    ForEach(FeedPost.sample) { post in
                        FeedPostCard(post: post)
                    }
                }
                .padding(Theme.Spacing.md)
            }
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
        }
    }
}

#Preview {
    FeedView()
}
