import SwiftUI

struct FeedView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Em construção — aqui vão aparecer as fotos de carros de quem você segue e da comunidade.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell")
                    }
                    NavigationLink(destination: MapView(scope: .feed)) {
                        Image(systemName: "globe")
                    }
                    NavigationLink(destination: EventsView()) {
                        Image(systemName: "ticket")
                    }
                }
            }
        }
    }
}

#Preview {
    FeedView()
}
