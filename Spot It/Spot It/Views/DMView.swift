import SwiftUI
import Supabase

private enum DMFilter: String, CaseIterable {
    case all = "All"
    case primary = "Primary"
    case general = "General"
    case requests = "Requests"
}

struct DMView: View {
    @State private var summaries: [ConversationSummary] = []
    @State private var isLoading = true
    @State private var search = ""
    @State private var filter: DMFilter = .all
    @FocusState private var isSearchFocused: Bool
    // Reseta a navegação sempre que a aba fica inativa — sem isso, sair
    // pro perfil de alguém e trocar de aba deixava o DM "preso" lá.
    @State private var path = NavigationPath()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: Theme.Spacing.md) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.top, Theme.Spacing.sm)
                }
                if summaries.isEmpty {
                    EmptyStateView(icon: "message", message: "Nenhuma mensagem ainda. Suas conversas aparecem aqui.")
                } else {
                    searchField
                    filterChips

                    List {
                        ForEach(summaries.filter { $0.otherUsername.localizedCaseInsensitiveContains(search) || search.isEmpty }) { conversation in
                            NavigationLink(destination: ChatThreadView(
                                conversationId: conversation.id,
                                otherUserId: conversation.otherUserId,
                                otherUsername: conversation.otherUsername,
                                otherAvatarUrl: conversation.otherAvatarUrl
                            )) {
                                row(conversation)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Spot It").font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: MapView(scope: .feed)) {
                        Image(systemName: "map")
                    }
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .onDisappear {
            path = NavigationPath()
            isSearchFocused = false
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            summaries = try await SupabaseService.fetchConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Buscar", text: $search)
                .focused($isSearchFocused)
        }
        .padding(Theme.Spacing.sm)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(DMFilter.allCases, id: \.self) { option in
                    Button {
                        filter = option
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline)
                            .fontWeight(filter == option ? .semibold : .regular)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(filter == option ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                            .foregroundStyle(filter == option ? .white : .primary)
                    }
                }
            }
        }
    }

    private func row(_ conversation: ConversationSummary) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(LinearGradient(colors: [.gray, .gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 52, height: 52)
                .overlay(Text(avatarInitials(for: conversation.otherUsername)).font(.subheadline).fontWeight(.bold).foregroundStyle(.white))

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.otherUsername).font(.subheadline).fontWeight(.semibold)
                Text(conversation.lastMessageText ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(timeAgo(conversation.lastMessageAt))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    private func avatarInitials(for username: String) -> String {
        String(username.prefix(2)).uppercased()
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ChatThreadView: View {
    let conversationId: UUID
    let otherUserId: UUID
    let otherUsername: String
    let otherAvatarUrl: String?

    @State private var messages: [DBMessage] = []
    @State private var myUserId: UUID?
    @State private var draft = ""
    @State private var errorMessage: String?
    @EnvironmentObject private var captureButtonVisibility: CaptureButtonVisibility
    @FocusState private var isDraftFocused: Bool

    private var avatarInitials: String {
        String(otherUsername.prefix(2)).uppercased()
    }
    private var avatarColors: [Color] { [.gray, .gray.opacity(0.6)] }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(messages) { message in
                        let fromMe = message.senderId == myUserId
                        HStack(alignment: .bottom, spacing: 8) {
                            if !fromMe {
                                Circle()
                                    .fill(LinearGradient(colors: avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 26, height: 26)
                                    .overlay(Text(avatarInitials).font(.system(size: 9)).fontWeight(.bold).foregroundStyle(.white))
                            } else {
                                Spacer(minLength: 40)
                            }

                            Text(message.text)
                                .font(.subheadline)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, 10)
                                .background(
                                    fromMe
                                        ? AnyShapeStyle(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        : AnyShapeStyle(Color(.secondarySystemBackground)),
                                    in: BubbleShape(fromMe: fromMe)
                                )
                                .foregroundStyle(fromMe ? .white : .primary)

                            if !fromMe { Spacer(minLength: 40) }
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { isDraftFocused = false }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, Theme.Spacing.md)
            }

            Divider()

            HStack(spacing: Theme.Spacing.sm) {
                TextField("Mensagem...", text: $draft)
                    .focused($isDraftFocused)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Color(.secondarySystemBackground), in: Capsule())

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : Color.accentColor)
                }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(Theme.Spacing.md)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavigationLink {
                    UserProfileView(username: otherUsername, avatarInitials: avatarInitials, avatarColors: avatarColors, userId: otherUserId)
                } label: {
                    Text(otherUsername)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .task { await load() }
        .onAppear { captureButtonVisibility.isHidden = true }
        .onDisappear {
            captureButtonVisibility.isHidden = false
            isDraftFocused = false
        }
    }

    private func load() async {
        myUserId = SupabaseService.client.auth.currentSession?.user.id
        errorMessage = nil
        do {
            messages = try await SupabaseService.fetchMessages(conversationId: conversationId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func send() async {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        errorMessage = nil
        do {
            try await SupabaseService.sendMessage(conversationId: conversationId, text: text)
            draft = ""
            messages = try await SupabaseService.fetchMessages(conversationId: conversationId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Bolha com "rabinho" — canto oposto ao autor fica reto (rounded-tr/tl-md,
/// igual referência), os outros 3 cantos bem arredondados.
private struct BubbleShape: Shape {
    let fromMe: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let corners: UIRectCorner = fromMe
            ? [.topLeft, .topRight, .bottomLeft]
            : [.topLeft, .topRight, .bottomRight]
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    DMView()
}
