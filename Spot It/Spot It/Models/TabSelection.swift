import Combine

enum MainTab: Int {
    case feed, dm, search, wallet, profile
}

/// Troca de aba programática — usado quando você toca no seu próprio
/// avatar/foto dentro do Feed: em vez de abrir o perfil "de visualização"
/// (UserProfileView, com botão Seguir/Bloquear), pula direto pra aba
/// Perfil de verdade.
final class TabSelection: ObservableObject {
    @Published var selected: MainTab = .feed
}
