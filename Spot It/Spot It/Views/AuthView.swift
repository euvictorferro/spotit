import SwiftUI
import AuthenticationServices
import CryptoKit

/// Formulário de login/cadastro — segunda tela do fluxo, aberta a partir da
/// WelcomeView já sabendo se é "Entrar" ou "Criar conta".
struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    let isSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var currentNonce: String?
    @State private var showForgotPassword = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text(isSignUp ? "Criar conta" : "Entrar")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, Theme.Spacing.md)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    fieldLabel("Email")
                    TextField("", text: $email, prompt: Text("seu@email.com").foregroundStyle(.white.opacity(0.4)))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                        .darkField()

                    fieldLabel("Senha")
                    SecureField("", text: $password, prompt: Text("••••••••").foregroundStyle(.white.opacity(0.4)))
                        .textContentType(isSignUp ? .newPassword : .password)
                        .foregroundStyle(.white)
                        .darkField()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isLoading {
                        WheelLoadingView(size: 22)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isSignUp ? "Criar conta" : "Entrar")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                if !isSignUp {
                    Button("Esqueci minha senha") { showForgotPassword = true }
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }

                HStack {
                    Rectangle().fill(.white.opacity(0.15)).frame(height: 1)
                    Text("OU")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Rectangle().fill(.white.opacity(0.15)).frame(height: 1)
                }
                .padding(.vertical, Theme.Spacing.xs)

                SignInWithAppleButton(.continue) { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.email]
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    Task { await handleAppleResult(result) }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .padding(Theme.Spacing.lg)
        }
        .background(AppGradientBackground())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(prefillEmail: email)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.white.opacity(0.6))
    }

    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        switch result {
        case .failure(let error):
            let nsError = error as NSError
            if nsError.code == ASAuthorizationError.canceled.rawValue { return }
            errorMessage = error.localizedDescription
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                errorMessage = "Não foi possível autenticar com a Apple."
                return
            }
            do {
                try await authService.signInWithApple(idToken: idToken, nonce: nonce)
            } catch {
                errorMessage = friendlyAuthError(error)
            }
        }
    }
}

/// Traduz as mensagens mais comuns do Supabase Auth (em inglês, cruas) pra
/// PT-BR — sem isso o usuário via literalmente "Invalid login credentials"
/// no meio de um app todo em português.
private func friendlyAuthError(_ error: Error) -> String {
    let raw = error.localizedDescription
    if raw.contains("Invalid login credentials") {
        return "Email ou senha incorretos."
    }
    if raw.contains("User already registered") {
        return "Já existe uma conta com esse email."
    }
    if raw.contains("Password should be at least") {
        return "A senha precisa ter pelo menos 6 caracteres."
    }
    if raw.contains("Unable to validate email address") || raw.contains("invalid format") {
        return "Esse email não parece válido."
    }
    if raw.contains("Email not confirmed") {
        return "Confirme seu email antes de entrar (verifique sua caixa de entrada)."
    }
    return raw
}

/// Sheet de "esqueci minha senha" — dispara o email de recuperação do
/// Supabase Auth. Sem isso, quem usa login por email/senha (não Apple)
/// ficava travado fora da conta pra sempre se esquecesse a senha.
private struct ForgotPasswordSheet: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var didSend = false

    init(prefillEmail: String) {
        _email = State(initialValue: prefillEmail)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("seu@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text("Vamos mandar um link pra você redefinir sua senha.")
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Recuperar senha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enviar") { Task { await send() } }
                        .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
            }
            .alert("Email enviado", isPresented: $didSend) {
                Button("OK") { dismiss() }
            } message: {
                Text("Se existir uma conta com esse email, você vai receber um link de recuperação em instantes.")
            }
        }
    }

    private func send() async {
        isSending = true
        errorMessage = nil
        do {
            try await authService.resetPassword(email: email.trimmingCharacters(in: .whitespaces))
            didSend = true
        } catch {
            errorMessage = friendlyAuthError(error)
        }
        isSending = false
    }
}

private extension View {
    /// Campo de texto escuro translúcido, igual à referência (fundo cinza
    /// escuro sobre o gradiente, sem o roundedBorder claro padrão do sistema).
    func darkField() -> some View {
        self
            .padding(Theme.Spacing.sm)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

// SHA256 nonce hashing per Apple's Sign in with Apple + Supabase docs.
private func randomNonceString(length: Int = 32) -> String {
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    while remainingLength > 0 {
        let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

private func sha256(_ input: String) -> String {
    let hashed = SHA256.hash(data: Data(input.utf8))
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

#Preview {
    NavigationStack {
        AuthView(isSignUp: false).environmentObject(AuthService())
    }
}
