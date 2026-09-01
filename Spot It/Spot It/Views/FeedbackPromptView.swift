import SwiftUI

/// "Essa informação foi útil?" com dois botões (👍/👎) — usado na tela de
/// Resultado da captura e na página de detalhe do carro salvo.
struct FeedbackPromptView: View {
    let question: LocalizedStringKey
    @Binding var answer: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(question).font(.subheadline).fontWeight(.medium)
            HStack(spacing: Theme.Spacing.sm) {
                button(icon: "hand.thumbsup", isSelected: answer == true) { answer = true }
                button(icon: "hand.thumbsdown", isSelected: answer == false) { answer = false }
            }
        }
    }

    private func button(icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? Color.accentColor : .secondary)
    }
}

#Preview {
    FeedbackPromptView(question: "Essa informação foi útil?", answer: .constant(nil)).padding()
}
