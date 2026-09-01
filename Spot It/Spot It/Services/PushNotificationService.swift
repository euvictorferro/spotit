import UIKit
import UserNotifications

/// Registro de push (device token) — pedir a permissão (UNUserNotification
/// Center) só habilita o alerta; ainda precisa registrar no APNs e mandar o
/// token pro backend pra alguém conseguir te mandar um push de verdade.
final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Chamado pelo AppDelegate quando o APNs devolve o token — salva no
    /// Supabase associado ao usuário logado.
    func didRegister(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            try? await SupabaseService.saveDeviceToken(token)
        }
    }
}

/// AppDelegate mínimo só pra receber o callback de registro do APNs — a UI
/// inteira do app continua 100% SwiftUI, isso não muda nada além disso.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationService.shared.didRegister(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // ponytail: falha de registro (ex.: simulador sem APNs, sem rede) —
        // sem push por ora, não é motivo de travar nada no app.
    }
}
