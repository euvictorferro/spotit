import SwiftUI

private enum DMFilter: String, CaseIterable {
    case all = "All"
    case primary = "Primary"
    case general = "General"
    case requests = "Requests"
}

struct DMView: View {
    @State private var conversations = DMConversation.sample
    @State private var search = ""
    @State private var filter: DMFilter = .all

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                searchField
                filterChips

                List {
                    ForEach($conversations.filter { $0.wrappedValue.username.localizedCaseInsensitiveContains(search) || search.isEmpty }) { $conversation in
                        NavigationLink(destination: ChatThreadView(conversation: $conversation)) {
                            row(conversation)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Buscar", text: $search)
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

    private func row(_ conversation: DMConversation) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(LinearGradient(colors: conversation.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 52, height: 52)
                .overlay(Text(conversation.avatarInitials).font(.subheadline).fontWeight(.bold).foregroundStyle(.white))

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.username).font(.subheadline).fontWeight(.semibold)
                Text(conversation.lastMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(conversation.timeAgo)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

struct ChatThreadView: View {
    @Binding var conversation: DMConversation
    @State private var draft = ""
    @EnvironmentObject private var captureButtonVisibility: CaptureButtonVisibility

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(conversation.messages) { message in
                        HStack(alignment: .bottom, spacing: 8) {
                            if !message.fromMe {
                                Circle()
                                    .fill(LinearGradient(colors: conversation.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 26, height: 26)
                                    .overlay(Text(conversation.avatarInitials).font(.system(size: 9)).fontWeight(.bold).foregroundStyle(.white))
                            } else {
                                Spacer(minLength: 40)
                            }

                            Text(message.text)
                                .font(.subheadline)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, 10)
                                .background(
                                    message.fromMe
                                        ? AnyShapeStyle(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        : AnyShapeStyle(Color(.secondarySystemBackground)),
                                    in: BubbleShape(fromMe: message.fromMe)
                                )
                                .foregroundStyle(message.fromMe ? .white : .primary)

                            if !message.fromMe { Spacer(minLength: 40) }
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }

            Divider()

            HStack(spacing: Theme.Spacing.sm) {
                TextField("Mensagem...", text: $draft)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Color(.secondarySystemBackground), in: Capsule())

                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : Color.accentColor)
                }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle(conversation.username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { captureButtonVisibility.isHidden = true }
        .onDisappear { captureButtonVisibility.isHidden = false }
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        conversation.messages.append(ChatMessage(fromMe: true, text: text))
        draft = ""
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
