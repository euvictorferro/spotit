import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var currentNonce: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Text("Spot It")
                        .font(.largeTitle.bold())
                        .padding(.top, Theme.Spacing.lg)

                    Picker("", selection: $isSignUp) {
                        Text("Entrar").tag(false)
                        Text("Criar conta").tag(true)
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: Theme.Spacing.sm) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Senha", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                    }
                    .textFieldStyle(.roundedBorder)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(isSignUp ? "Criar conta" : "Entrar")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)

                    SignInWithAppleButton(.continue) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        Task { await handleAppleResult(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(AppGradientBackground())
        }
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
            errorMessage = error.localizedDescription
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
                errorMessage = error.localizedDescription
            }
        }
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
    AuthView().environmentObject(AuthService())
}
