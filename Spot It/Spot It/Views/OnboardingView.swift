import SwiftUI
import PhotosUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var username = ""
    @State private var displayName = ""
    @State private var bio = ""
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
            profileForm
            .background(AppGradientBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sair", role: .destructive) {
                        Task { try? await authService.signOut() }
                    }
                }
            }
        }
    }

    private var profileForm: some View {
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
                    TextField("Bio (opcional)", text: $bio, axis: .vertical)
                        .lineLimit(2...4)
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
                        WheelLoadingView(size: 22)
                    } else {
                        Text("Continuar").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isUsernameValid || isLoading)
            }
            .padding(Theme.Spacing.lg)
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
                bio: bio.isEmpty ? nil : bio,
                avatarData: avatarData
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// 2º passo do onboarding — pede notificação e localização de cara, uma
/// vez só, no momento em que o usuário está mais disposto a aceitar (logo
/// depois de criar a conta), em vez de pedir cada uma escondida no meio de
/// uma feature depois.
struct PermissionsStepView: View {
    var onDone: () -> Void
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
                Text("Ative as permissões")
                    .font(.title2.bold())
                Text("Pra te avisar de curtidas, comentários, seguidores e mensagens, e marcar no mapa onde você avista cada carro.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }

            Spacer()

            Button {
                Task { await requestAll() }
            } label: {
                if isRequesting {
                    WheelLoadingView(size: 22)
                } else {
                    Text("Ativar notificações e localização").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRequesting)

            Button("Agora não") { onDone() }
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.lg)
    }

    private func requestAll() async {
        isRequesting = true
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        await MainActor.run { PushNotificationService.shared.registerForRemoteNotifications() }
        LocationService.shared.requestPermissionIfNeeded()
        isRequesting = false
        onDone()
    }
}

#Preview {
    OnboardingView().environmentObject(AuthService())
}
