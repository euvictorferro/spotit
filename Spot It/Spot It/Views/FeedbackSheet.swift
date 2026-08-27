import SwiftUI

/// Aberto pelo "..." no cabeçalho de cada seção. Por enquanto os taps não
/// mandam nada pra lugar nenhum (sem backend de feedback ainda) — só fecha.
struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Text("Algum feedback?").font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }
            }

            row(icon: "heart", label: "Gostei dessas funcionalidades")
            row(icon: "heart.slash", label: "Não gostei dessas funcionalidades")
            row(icon: "square.grid.2x2", label: "Sugerir funcionalidade", showsChevron: true)
            row(icon: "text.bubble", label: "Mais sugestões", showsChevron: true)
        }
        .padding(Theme.Spacing.md)
        .presentationDetents([.height(340)])
    }

    private func row(icon: String, label: String, showsChevron: Bool = false) -> some View {
        Button {
            dismiss()
        } label: {
            HStack {
                Image(systemName: icon).frame(width: 22)
                Text(label)
                Spacer()
                if showsChevron {
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .foregroundStyle(.primary)
        }
    }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) { FeedbackSheet() }
}
