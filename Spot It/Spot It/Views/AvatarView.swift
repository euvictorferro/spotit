import SwiftUI

/// Foto de perfil real (AsyncImage) com fallback pro círculo de iniciais —
/// usado em qualquer lugar que mostra o avatar de alguém (Feed, perfil de
/// outro usuário, comentários). Sem isso, todo avatar_url salvo no banco
/// nunca aparecia — sempre caía no círculo de iniciais/gradiente.
struct AvatarView: View {
    let url: String?
    let initials: String
    let colors: [Color]
    var size: CGFloat = 30

    var body: some View {
        Group {
            if let url, let imageUrl = URL(string: url) {
                AsyncImage(url: imageUrl) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        initialsCircle
                    }
                }
            } else {
                initialsCircle
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsCircle: some View {
        Circle()
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Text(initials).font(.system(size: size * 0.4)).fontWeight(.bold).foregroundStyle(.white))
    }
}

extension AvatarView {
    init(user: SearchableUser, url: String?, size: CGFloat = 30) {
        self.init(url: url, initials: user.avatarInitials, colors: user.avatarColors, size: size)
    }
}
