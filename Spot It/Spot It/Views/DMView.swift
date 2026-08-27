import SwiftUI

struct DMView: View {
    @State private var conversations = DMConversation.sample

    var body: some View {
        NavigationStack {
            List {
                ForEach($conversations) { $conversation in
                    NavigationLink(destination: ChatThreadView(conversation: $conversation)) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Circle()
                                .fill(LinearGradient(colors: conversation.avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 46, height: 46)
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
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct ChatThreadView: View {
    @Binding var conversation: DMConversation
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(conversation.messages) { message in
                        HStack {
                            if message.fromMe { Spacer(minLength: 40) }
                            Text(message.text)
                                .font(.subheadline)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(message.fromMe ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundStyle(message.fromMe ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            if !message.fromMe { Spacer(minLength: 40) }
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }

            Divider()

            HStack(spacing: Theme.Spacing.sm) {
                TextField("Mensagem...", text: $draft)
                    .textFieldStyle(.roundedBorder)
                Button("Enviar") { send() }
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle(conversation.username)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        conversation.messages.append(ChatMessage(fromMe: true, text: text))
        draft = ""
    }
}

#Preview {
    DMView()
}
