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

    private var client: SupabaseClient { SupabaseService.client }

    func start() async {
        session = client.auth.currentSession
        await reloadProfile()

        for await state in client.auth.authStateChanges {
            session = state.session
            await reloadProfile()
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
                .insert(NewProfile(id: userId, username: username, display_name: displayName, avatar_url: avatarUrl))
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

        let avatarUrl = try await uploadAvatarIfNeeded(avatarData)

        struct ProfileUpdate: Encodable {
            let display_name: String?
            let bio: String?
            let avatar_url: String?
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
