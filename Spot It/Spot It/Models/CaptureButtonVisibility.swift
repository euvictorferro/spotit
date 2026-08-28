import Combine
import SwiftUI

/// Controla se o botão flutuante de Captura aparece — algumas telas (chat
/// individual do DM) escondem ele pra não atrapalhar o teclado/input.
final class CaptureButtonVisibility: ObservableObject {
    @Published var isHidden = false
}
