import SwiftUI

/// Sheet de denúncia reutilizado no post (feed) e no perfil de outro
/// usuário — exigido pela App Store guideline 1.2 (apps com UGC precisam
/// de um jeito de denunciar conteúdo/usuário).
struct ReportSheet: View {
    let onSubmit: (String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didSubmit = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Motivo") {
                    TextField("Descreva o problema", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                }
            }
            .navigationTitle("Denunciar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enviar") { Task { await submit() } }
                        .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .alert("Denúncia enviada", isPresented: $didSubmit) {
                Button("OK") { dismiss() }
            } message: {
                Text("Vamos revisar em até 24h.")
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            try await onSubmit(reason.trimmingCharacters(in: .whitespacesAndNewlines))
            didSubmit = true
        } catch {
            errorMessage = "Não deu pra enviar agora. Tente de novo."
        }
        isSubmitting = false
    }
}
