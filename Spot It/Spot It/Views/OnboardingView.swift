import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var username = ""
    @State private var displayName = ""
    @State private var avatarData: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var isUsernameValid: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 3 && trimmed.count <= 20 && !trimmed.contains(" ")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Text("Cria seu perfil")
                        .font(.title2.bold())

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        if let avatarData, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 88, height: 88)
                                .overlay(Image(systemName: "camera.fill"))
                        }
                    }
                    .onChange(of: pickerItem) { _, newItem in
                        Task {
                            avatarData = try? await newItem?.loadTransferable(type: Data.self)
                        }
                    }

                    VStack(spacing: Theme.Spacing.sm) {
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Nome (opcional)", text: $displayName)
                    }
                    .textFieldStyle(.roundedBorder)

                    if !username.isEmpty && !isUsernameValid {
                        Text("Username precisa ter 3-20 caracteres, sem espaço.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
                            ProgressView()
                        } else {
                            Text("Continuar").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isUsernameValid || isLoading)
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
            try await authService.createProfile(
                username: username.trimmingCharacters(in: .whitespaces),
                displayName: displayName.isEmpty ? nil : displayName,
                avatarData: avatarData
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    OnboardingView().environmentObject(AuthService())
}
