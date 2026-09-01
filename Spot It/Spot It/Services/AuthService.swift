import Combine
import Foundation
import Supabase

enum AuthServiceError: LocalizedError {
    case usernameTaken

    var errorDescription: String? {
        switch self {
        case .usernameTaken: return "Esse username já está em uso."
        }
    }
}

@MainActor
final class AuthService: ObservableObject {
    @Published var session: Session?
    @Published var profile: Profile?
    @Published var isReady = false

    private var client: SupabaseClient { SupabaseService.client }

    func start() async {
        session = client.auth.currentSession
        await reloadProfile()
        isReady = true

        for await state in client.auth.authStateChanges {
            let previousUserId = session?.user.id
            session = state.session
            if state.session?.user.id != previousUserId {
                await reloadProfile()
            }
        }
    }

    private func reloadProfile() async {
        guard let userId = session?.user.id else {
            profile = nil
            return
        }
        profile = try? await client.from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Exclusão de conta self-service (RPC `delete_user`, migration 0016) —
    /// apaga a linha em auth.users, o que cascateia pra profile/posts/wallet/
    /// follows/DMs/notificações/eventos. Exigido pela App Store (5.1.1v).
    func deleteAccount() async throws {
        try await client.rpc("delete_user").execute()
        session = nil
        profile = nil
    }

    func createProfile(username: String, displayName: String?, avatarData: Data?) async throws {
        guard let userId = session?.user.id else { throw SupabaseError.notSignedIn }

        let avatarUrl = try await uploadAvatarIfNeeded(avatarData)

        struct NewProfile: Encodable {
            let id: UUID
            let username: String
            let display_name: String?
            let avatar_url: String?
        }

        do {
            try await client.from("profiles")
                .upsert(NewProfile(id: userId, username: username, display_name: displayName, avatar_url: avatarUrl))
                .execute()
        } catch {
            if error.localizedDescription.contains("duplicate key") {
                throw AuthServiceError.usernameTaken
            }
            throw error
        }

        await reloadProfile()
    }

    func updateProfile(displayName: String?, bio: String?, avatarData: Data?) async throws {
        guard let userId = session?.user.id else { throw SupabaseError.notSignedIn }

        // ponytail: only avatar_url is conditionally included — displayName/bio empty-string-clears
        // semantics were already the existing behavior, not something this fix needs to change.
        struct ProfileUpdate: Encodable {
            let display_name: String?
            let bio: String?
            let avatar_url: String?

            enum CodingKeys: String, CodingKey {
                case display_name, bio, avatar_url
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(display_name, forKey: .display_name)
                try container.encode(bio, forKey: .bio)
                if let avatar_url {
                    try container.encode(avatar_url, forKey: .avatar_url)
                }
            }
        }

        var avatarUrl: String?
        if let avatarData {
            avatarUrl = try await uploadAvatarIfNeeded(avatarData)
        }

        try await client.from("profiles")
            .update(ProfileUpdate(display_name: displayName, bio: bio, avatar_url: avatarUrl))
            .eq("id", value: userId)
            .execute()

        await reloadProfile()
    }

    private func uploadAvatarIfNeeded(_ data: Data?) async throws -> String? {
        guard let data else { return nil }
        let fileName = "\(UUID().uuidString).jpg"
        try await client.storage.from("car-photos").upload(fileName, data: data)
        return try client.storage.from("car-photos").getPublicURL(path: fileName).absoluteString
    }
}
